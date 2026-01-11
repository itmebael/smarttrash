// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { corsHeaders } from "../_shared/cors.ts"

console.log("Create User Function Initialized")

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Verify the caller is an authenticated Admin
    // We create a client with the user's Auth header to check their identity
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      throw new Error('Not authenticated')
    }

    // Check if the caller is an admin in the public.users table
    const { data: callerProfile, error: profileError } = await supabaseClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError || callerProfile?.role !== 'admin') {
      throw new Error('Unauthorized: Only admins can create new accounts')
    }

    // 2. Parse request body
    const { 
      email, 
      password, 
      name, 
      phone_number, 
      role, 
      department, 
      position,
      address,
      city,
      state,
      zip_code,
      age,
      date_of_birth,
      emergency_contact,
      emergency_phone
    } = await req.json()

    if (!email || !password || !name) {
      throw new Error('Missing required fields: email, password, name')
    }

    // 3. Use Service Role Key to perform admin operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 4. Create user in Supabase Auth (auto-confirmed)
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm the email so they can login immediately
      user_metadata: { 
        name, 
        phone_number, 
        role: role || 'staff' 
      }
    })

    if (authError) throw authError
    if (!authData.user) throw new Error('Failed to create auth user')

    const newUserId = authData.user.id

    // 5. Insert or Update user in public.users table
    // Using upsert to handle cases where a trigger might have already created a partial record
    const { error: dbError } = await supabaseAdmin
      .from('users')
      .upsert({
        id: newUserId,
        email,
        name,
        phone_number,
        role: role || 'staff',
        department: department || null,
        position: position || null,
        address: address || null,
        city: city || null,
        state: state || null,
        zip_code: zip_code || null,
        age: age || null,
        date_of_birth: date_of_birth || null,
        emergency_contact: emergency_contact || null,
        emergency_phone: emergency_phone || null,
        created_at: new Date().toISOString(),
        is_active: true,
        updated_at: new Date().toISOString()
      })

    if (dbError) {
      // If DB insert fails, we should probably clean up the auth user to maintain consistency
      // await supabaseAdmin.auth.admin.deleteUser(newUserId)
      throw new Error(`Database insert failed: ${dbError.message}`)
    }

    // 6. Return success
    return new Response(
      JSON.stringify({ 
        user: authData.user, 
        message: 'User created successfully' 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error creating user:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
        status: 400 
      }
    )
  }
})
