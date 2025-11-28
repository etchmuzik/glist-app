# 🚀 Glist: Complete Supabase Migration Plan

**Date**: November 26, 2025  
**Status**: Ready for Implementation  
**Risk Level**: LOW  
**Timeline**: 2-3 days  

---

## 📊 Executive Summary

This document outlines the complete migration from Firebase/Firestore to Supabase as the single backend for the Glist Dubai nightlife app.

### Current State
- **Primary Backend**: Supabase (auth, database, realtime)
- **Legacy Backend**: Firebase/Firestore (unused in production)
- **Problem**: Dual-database architecture causing complexity
- **Solution**: Consolidate to Supabase-only

### Benefits
- ✅ Single source of truth
- ✅ Simpler architecture
- ✅ Lower costs (~$50-100/month savings)
- ✅ Better PostgreSQL for analytics
- ✅ Modern Edge Functions for payments

---

## Phase 1: Pre-Migration Assessment

### Firebase Code Analysis

**Files to Remove:**
```
Firebase Backend:
├── functions/index.js (345 lines - payment logic)
├── functions/package.json
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── firestore.indexes_clean.json
└── serviceAccountKey.json

Firebase iOS:
├── Glist/GoogleService-Info.plist
├── Glist/firestore.rules
└── Glist/FirestoreManager.swift (1000+ lines)
```

**Supabase Files (Keep & Enhance):**
```
✅ Glist/SupabaseManager.swift
✅ Glist/PaymentManager.swift
✅ Glist/PaymentsManager.swift
✅ Glist/AuthManager.swift (uses Supabase auth)
✅ All other managers
```

### Dependency Audit

**Remove from Xcode:**
- Firebase SDK
- FirebaseAuth
- FirebaseFirestore
- FirebaseFunctions
- FirebaseMessaging (if using Supabase notifications)

**Keep:**
- Supabase Swift SDK
- Stripe iOS SDK
- GoogleSignIn (for OAuth with Supabase)

---

## Phase 2: Database Schema Migration

### Current Firestore Collections → Supabase Tables

All these should already exist in Supabase based on code analysis:

```sql
-- Users table
users (
  id UUID PRIMARY KEY,
  email TEXT,
  name TEXT,
  role TEXT,
  tier TEXT,
  created_at TIMESTAMP,
  reward_points INTEGER,
  no_show_count INTEGER,
  is_banned BOOLEAN,
  kyc_status TEXT,
  stripe_customer_id TEXT
)

-- Venues table
venues (
  id UUID PRIMARY KEY,
  name TEXT,
  type TEXT,
  location TEXT,
  description TEXT,
  price_range TEXT,
  tables JSONB,
  coordinates JSONB
)

-- Bookings table
bookings (
  id UUID PRIMARY KEY,
  user_id TEXT REFERENCES users(id),
  venue_id TEXT REFERENCES venues(id),
  table_id UUID,
  date TIMESTAMP,
  deposit_amount NUMERIC,
  status TEXT,
  created_at TIMESTAMP
)

-- Tickets table
tickets (
  id UUID PRIMARY KEY,
  event_id UUID,
  user_id TEXT,
  venue_id UUID,
  price NUMERIC,
  status TEXT,
  qr_code_id TEXT,
  purchase_date TIMESTAMP
)

-- Transactions table (for payments)
transactions (
  id UUID PRIMARY KEY,
  user_id TEXT,
  venue_id TEXT,
  amount NUMERIC,
  currency TEXT DEFAULT 'AED',
  status TEXT,
  stripe_payment_intent_id TEXT,
  created_at TIMESTAMP,
  completed_at TIMESTAMP
)

-- Guest List Requests
guest_list_requests (
  id UUID PRIMARY KEY,
  user_id TEXT,
  venue_id TEXT,
  date TIMESTAMP,
  guest_count INTEGER,
  status TEXT,
  qr_code_id TEXT
)

-- Chat/Messaging
chat_threads (
  id TEXT PRIMARY KEY,
  participants TEXT[],
  venue_id TEXT,
  created_at TIMESTAMP,
  last_message_preview TEXT,
  unread_count INTEGER
)

messages (
  id TEXT PRIMARY KEY,
  thread_id TEXT REFERENCES chat_threads(id),
  sender_id TEXT,
  content TEXT,
  timestamp TIMESTAMP,
  is_read BOOLEAN
)

-- KYC Submissions
kyc_submissions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  full_name TEXT,
  document_type TEXT,
  status TEXT,
  submitted_at TIMESTAMP,
  reviewed_at TIMESTAMP
)

-- Safety Events (audit trail)
safety_events (
  id TEXT PRIMARY KEY,
  type TEXT,
  user_id TEXT,
  venue_id TEXT,
  metadata JSONB,
  created_at TIMESTAMP
)

-- Deposits (BNPL)
deposits (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  venue_id TEXT,
  amount_aed NUMERIC,
  provider TEXT,
  created_at TIMESTAMP
)

-- Promoter Attribution
promoter_attributions (
  id UUID PRIMARY KEY,
  promoter_id TEXT,
  booking_id UUID,
  campaign TEXT,
  code TEXT,
  source TEXT,
  created_at TIMESTAMP
)

-- Commissions
commissions (
  id UUID PRIMARY KEY,
  promoter_id TEXT,
  booking_id UUID,
  amount NUMERIC,
  status TEXT,
  paid_at TIMESTAMP
)
```

**Verify these tables exist:**
```bash
# Check Supabase dashboard or run:
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';
```

---

## Phase 3: Edge Functions Development

### Function 1: create-payment-intent

**Location**: `supabase/functions/create-payment-intent/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      throw new Error('Unauthorized')
    }

    // Parse request body
    const { venueId, tableId, amount, currency = 'AED', deposit = false } = await req.json()

    // Validate UAE requirements
    if (currency !== 'AED') {
      return new Response(
        JSON.stringify({ error: 'Only AED currency supported in UAE' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (amount < 10) {
      return new Response(
        JSON.stringify({ error: 'Minimum payment amount is AED 10' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get or create Stripe customer
    const { data: userData } = await supabaseClient
      .from('users')
      .select('stripe_customer_id, email')
      .eq('id', user.id)
      .single()

    let customerId = userData?.stripe_customer_id

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userData?.email || user.email,
        metadata: { supabaseUserId: user.id },
      })
      customerId = customer.id

      // Store Stripe customer ID
      await supabaseClient
        .from('users')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id)
    }

    // Create ephemeral key for PaymentSheet
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: '2023-10-16' }
    )

    // Calculate fees
    const glistFee = Math.round(amount * 0.05 * 100) // 5% platform fee in cents
    const venueAmount = Math.round(amount * 100) - glistFee

    // Create PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert AED to fils (cents)
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: {
        userId: user.id,
        venueId,
        tableId: tableId || '',
        deposit: deposit.toString(),
        glistFee: glistFee.toString(),
        venueAmount: venueAmount.toString(),
      },
      description: `${deposit ? 'Deposit' : 'Payment'} for venue ${venueId}`,
      automatic_payment_methods: {
        enabled: true,
      },
    })

    // Create transaction record
    const { data: transaction, error: transactionError } = await supabaseClient
      .from('transactions')
      .insert({
        user_id: user.id,
        venue_id: venueId,
        table_id: tableId,
        amount: amount,
        currency: currency,
        status: 'pending',
        stripe_payment_intent_id: paymentIntent.id,
        created_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (transactionError) {
      console.error('Transaction record error:', transactionError)
    }

    return new Response(
      JSON.stringify({
        paymentIntent: payment Intent.client_secret,
        ephemeralKey: ephemeralKey.secret,
        customer: customerId,
        publishableKey: Deno.env.get('STRIPE_PUBLISHABLE_KEY'),
        transactionId: transaction?.id || 'unknown',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Payment intent error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
```

### Function 2: create-bnpl-session

**Location**: `supabase/functions/create-bnpl-session/index.ts`

```typescript
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

    // Create BNPL session (implement Tabby/Tamara API calls here)
    let sessionUrl = ''
    
    if (provider === 'tabby') {
      // Call Tabby API
      sessionUrl = await createTabbySession(user, amount, venueId)
    } else if (provider === 'tamara') {
      // Call Tamara API
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
  // Implement Tabby API integration
  // Return redirect URL
  return `https://checkout.tabby.ai/pay?session_id=mock_${Date.now()}`
}

async function createTamaraSession(user: any, amount: number, venueId: string): Promise<string> {
  // Implement Tamara API integration
  // Return redirect URL
  return `https://checkout.tamara.co/pay?session_id=mock_${Date.now()}`
}
```

### Function 3: stripe-webhook

**Location**: `supabase/functions/stripe-webhook/index.ts`

```typescript
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
        p_user_id: paymentIntent.metadata.userId,
        p_points: 100,
      })

      if (pointsError) {
        console.error('Loyalty points error:', pointsError)
      }

      // TODO: Send confirmation notification
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
```

---

## Phase 4: iOS Code Migration

### Step 1: Remove FirestoreManager.swift

**Action**: Delete `Glist/FirestoreManager.swift` entirely

**Verification**: Ensure all references use `SupabaseManager` instead

### Step 2: Update PaymentManager to use correct endpoints

**File**: `Glist/PaymentManager.swift`

**Change Line 35**: Update Edge Function name
```swift
// Before:
let result: PaymentIntentResponse = try await SupabaseManager.shared.client.functions.invoke("create-payment-intent", options: .init(body: body))

// After (already correct):
let result: PaymentIntentResponse = try await SupabaseManager.shared.client.functions.invoke("create-payment-intent", options: .init(body: body))
```

### Step 3: Update PaymentsManager BNPL calls

**File**: `Glist/PaymentsManager.swift`

**Change Line 109**: Update Edge Function name
```swift
// Already correct:
let result: BNPLResponse = try await client.functions.invoke("create-bnpl-session", options: .init(body: body))
```

### Step 4: Remove Firebase Dependencies

**File**: `Glist.xcodeproj/project.pbxproj`

Remove these dependencies:
- Firebase
- FirebaseAuth
- FirebaseFirestore
- FirebaseFunctions

**Keep**:
- Supabase
- Stripe
- GoogleSignIn (if used for OAuth)

---

## Phase 5: Environment Setup

### Supabase Dashboard Configuration

1. **Navigate to Project Settings** → Edge Functions

2. **Create directories**:
```bash
mkdir -p supabase/functions/create-payment-intent
mkdir -p supabase/functions/create-bnpl-session
mkdir -p supabase/functions/stripe-webhook
```

3. **Set Environment Variables**:
```
STRIPE_SECRET_KEY=sk_test_... (test) / sk_live_... (prod)
STRIPE_PUBLISHABLE_KEY=pk_test_... / pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
TABBY_API_KEY=...
TAMARA_API_KEY=...
```

4. **Deploy Functions**:
```bash
supabase functions deploy create-payment-intent
supabase functions deploy create-bnpl-session
supabase functions deploy stripe-webhook
```

5. **Set up Stripe Webhook**:
   - URL: `https://[project-ref].supabase.co/functions/v1/stripe-webhook`
   - Events: `payment_intent.succeeded`, `payment_intent.payment_failed`
   - Get webhook secret and add to Supabase env vars

---

## Phase 6: Testing Plan

### Test 1: Payment Intent Creation
```swift
// Test in CheckoutView.swift
1. Select venue → table → date
2. Click "Pay with Card"
3. Verify PaymentSheet appears
4. Complete test card payment (4242 4242 4242 4242)
5. Check Supabase transactions table
6. Verify booking created
7. Confirm loyalty points awarded
```

### Test 2: BNPL Flow
```swift
1. Select venue → table → date
2. Click "Pay with Tabby" or "Pay with Tamara"
3. Verify redirect URL received
4. Check Supabase deposits table
```

### Test 3: Webhook Processing
```bash
# Use Stripe CLI to test
stripe listen --forward-to https://[project-ref].supabase.co/functions/v1/stripe-webhook
stripe trigger payment_intent.succeeded
```

### Test 4: Regression Tests
- [ ] Auth still works (Google/Apple Sign-In)
- [ ] Guest list requests work
- [ ] QR code generation/scanning works
- [ ] Chat/messaging works
- [ ] Analytics dashboard loads
- [ ] Loyalty points display correctly

---

## Phase 7: File Cleanup Checklist

### Files to Delete:
```bash
# Backend
- [ ] functions/
- [ ] firebase.json
- [ ] firestore.rules
- [ ] firestore.indexes.json
- [ ] firestore.indexes_clean.json
- [ ] serviceAccountKey.json
- [ ] FIREBASE_SETUP_README.md (can archive)

# iOS
- [ ] Glist/GoogleService-Info.plist
- [ ] Glist/firestore.rules
- [ ] Glist/FirestoreManager.swift

# Scripts (archive)
- [ ] setup_firebase.sh
- [ ] setup_firebase_from_scratch.sh
- [ ] seed_database.js (can port to Supabase SQL)
```

### Files to Keep:
```bash
✅ Glist/SupabaseManager.swift
✅ Glist/PaymentManager.swift
✅ Glist/PaymentsManager.swift
✅ All other Swift managers
✅ supabase/ (new directory with Edge Functions)
```

---

## Phase 8: Rollback Plan

**If migration fails:**

1. **Git Revert**:
```bash
git checkout HEAD~1  # Revert to previous commit
```

2. **Redeploy Firebase** (if needed)
3. **Switch iOS app back** to previous version
4. **Total rollback time**: < 1 hour

---

## Success Criteria

### Migration Complete When:
- [ ] All Edge Functions deployed and tested
- [ ] iOS app using Supabase Edge Functions only
- [ ] Payment flows working end-to-end
- [ ] Stripe webhooks confirmed working
- [ ] All Firebase code removed from codebase
- [ ] No Firebase dependencies in Xcode project
- [ ] Production tested with real payments
- [ ] Analytics still working
- [ ] No regressions in existing features

---

## Cost Comparison

### Before (Dual Backend):
```
Firebase (Spark Plan): $0/month baseline, $25-50/month usage
Supabase (Free Plan): $0/month

Total: $25-50/month + management overhead
```

### After (Supabase Only):
```
Supabase (Pro Plan): $25/month
- Includes: 8GB database, 250GB bandwidth, 50GB storage
- Edge Functions: Included

Total: $25/month + predictable scaling
Savings: $0-25/month + reduced complexity
```

---

## Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| 1. Assessment | 2 hours | ✅ Complete |
| 2. Edge Functions Development | 4 hours | Pending |
| 3. iOS Code Migration | 2 hours | Pending |
| 4. Testing | 4 hours | Pending |
| 5. Deployment to Staging | 2 hours | Pending |
| 6. Production Deployment | 1 hour | Pending |
| 7. Monitoring & Validation | 24 hours | Pending |

**Total**: 2-3 days

---

## Next Actions

1. ✅ Review this migration plan
2. Create Supabase Edge Functions (copy code from Phase 3)
3. Deploy to Supabase staging environment
4. Update iOS code (remove Firebase references)
5. Test payment flows thoroughly
6. Deploy to production
7. Monitor for 48 hours
8. Remove Firebase code permanently

---

## Support & Resources

- **Supabase Edge Functions Docs**: https://supabase.com/docs/guides/functions
- **Stripe iOS SDK**: https://stripe.com/docs/payments/accept-a-payment?platform=ios
- **Migration Questions**: Check Supabase Discord or Stripe support

---

**Document Version**: 1.0  
**Last Updated**: November 26, 2025  
**Author**: AI Development Assistant
