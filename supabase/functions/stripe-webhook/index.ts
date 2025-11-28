import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')
  const body = await req.text()

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature!,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    )
  } catch (err) {
    console.error(`Webhook signature verification failed: ${err.message}`)
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  // Initialize Supabase admin client
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // Handle payment success
  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object as Stripe.PaymentIntent

    console.log(`💰 Payment succeeded: ${paymentIntent.id}`)

    // Update transaction status
    const { data: transaction } = await supabaseClient
      .from('transactions')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
      })
      .eq('stripe_payment_intent_id', paymentIntent.id)
      .select()
      .single()

    if (transaction) {
      // Create booking record
      const { error: bookingError } = await supabaseClient
        .from('bookings')
        .insert({
          user_id: paymentIntent.metadata.userId,
          venue_id: paymentIntent.metadata.venueId,
          table_id: paymentIntent.metadata.tableId || null,
          date: new Date().toISOString(),
          deposit_amount: paymentIntent.amount / 100,
          status: paymentIntent.metadata.deposit === 'true' ? 'holdPending' : 'confirmed',
          created_at: new Date().toISOString(),
        })

      if (bookingError) {
        console.error('Booking creation error:', bookingError)
      }

      // Award loyalty points (100 points per booking)
      const { error: pointsError } = await supabaseClient.rpc('add_reward_points', {
        user_id: paymentIntent.metadata.userId,
        points: 100,
      })

      if (pointsError) {
        console.error('Loyalty points error:', pointsError)
      }

      // TODO: Send confirmation notification via Supabase Realtime or external service
      console.log(`✅ Booking confirmed for user ${paymentIntent.metadata.userId}`)
    }
  }

  // Handle payment failure
  if (event.type === 'payment_intent.payment_failed') {
    const paymentIntent = event.data.object as Stripe.PaymentIntent

    console.log(`❌ Payment failed: ${paymentIntent.id}`)

    await supabaseClient
      .from('transactions')
      .update({ status: 'failed' })
      .eq('stripe_payment_intent_id', paymentIntent.id)
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
