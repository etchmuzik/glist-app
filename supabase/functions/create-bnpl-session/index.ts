import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      throw new Error('Unauthorized')
    }

    const { venueId, amount, provider } = await req.json()

    // Validate provider
    if (!['tabby', 'tamara'].includes(provider)) {
      return new Response(
        JSON.stringify({ error: 'Invalid BNPL provider' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate amount (minimum AED 100 for BNPL typically)
    if (amount < 100) {
      return new Response(
        JSON.stringify({ error: 'Minimum BNPL amount is AED 100' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create BNPL session (implement Tabby/Tamara API calls here)
    let sessionUrl = ''
    
    if (provider === 'tabby') {
      sessionUrl = await createTabbySession(user, amount, venueId)
    } else if (provider === 'tamara') {
      sessionUrl = await createTamaraSession(user, amount, venueId)
    }

    // Store deposit record
    const { data: deposit, error } = await supabaseClient
      .from('deposits')
      .insert({
        user_id: user.id,
        venue_id: venueId,
        amount_aed: amount,
        provider: provider,
        status: 'pending',
        created_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) {
      console.error('Deposit record error:', error)
    }

    return new Response(
      JSON.stringify({
        transactionId: deposit?.id || 'unknown',
        redirectUrl: sessionUrl,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('BNPL session error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

// Placeholder functions for BNPL providers
async function createTabbySession(user: any, amount: number, venueId: string): Promise<string> {
  // TODO: Implement Tabby API integration
  // const tabbyApiKey = Deno.env.get('TABBY_API_KEY')
  // Call Tabby checkout API and return redirect URL
  console.log(`Creating Tabby session for user ${user.id}, amount ${amount}, venue ${venueId}`)
  return `https://checkout.tabby.ai/pay?session_id=mock_${Date.now()}`
}

async function createTamaraSession(user: any, amount: number, venueId: string): Promise<string> {
  // TODO: Implement Tamara API integration
  // const tamaraApiKey = Deno.env.get('TAMARA_API_KEY')
  // Call Tamara checkout API and return redirect URL
  console.log(`Creating Tamara session for user ${user.id}, amount ${amount}, venue ${venueId}`)
  return `https://checkout.tamara.co/pay?session_id=mock_${Date.now()}`
}
