// Supabase Edge Function to send emails via EmailJS
// This runs in a browser-like environment, so EmailJS will accept it

// @deno-types="https://deno.land/x/types/index.d.ts"
// @ts-ignore - Deno types are available at runtime
import { serve } from "https://deno.land/std@0.192.0/http/server.ts"

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// EmailJS configuration
const EMAILJS_SERVICE_ID = 'service_uo9e3xj'
const EMAILJS_TEMPLATE_ID = 'template_8ixe808'
const EMAILJS_PUBLIC_KEY = 'NxsdgyvCGJ90Qm2cz'
const EMAILJS_API_URL = 'https://api.emailjs.com/api/v1.0/email/send'

// Type definitions
interface EmailRequest {
  to_email: string
  staff_name: string
  task_title: string
  task_description?: string
  trashcan_name?: string
  location?: string
  priority?: string
  due_date?: string
  estimated_duration?: string
  assigned_date?: string
}

// Main handler function
async function handleRequest(req: Request): Promise<Response> {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Method not allowed. Use POST.',
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 405,
      },
    )
  }

  try {
    // Parse request body
    let body: EmailRequest
    try {
      body = await req.json() as EmailRequest
    } catch (parseError) {
      console.error('JSON parse error:', parseError)
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Invalid JSON in request body',
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        },
      )
    }

    // Validate required fields
    if (!body.to_email || typeof body.to_email !== 'string' || !body.to_email.includes('@')) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Invalid or missing to_email field',
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        },
      )
    }

    if (!body.staff_name || typeof body.staff_name !== 'string' || body.staff_name.trim().length === 0) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Invalid or missing staff_name field',
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        },
      )
    }

    if (!body.task_title || typeof body.task_title !== 'string' || body.task_title.trim().length === 0) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Invalid or missing task_title field',
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        },
      )
    }

    console.log('📧 Sending email via EmailJS from Edge Function...')
    console.log('   To:', body.to_email)
    console.log('   Task:', body.task_title)
    console.log('   Staff:', body.staff_name)

    // Prepare EmailJS template parameters
    const templateParams = {
      to_email: body.to_email,
      to_name: body.staff_name,
      subject: `📋 New Task Assigned: ${body.task_title}`,
      staff_name: body.staff_name,
      task_title: body.task_title || '',
      task_description: body.task_description || '',
      trashcan_name: body.trashcan_name || '',
      location: body.location || '',
      priority: body.priority || 'medium',
      due_date: body.due_date || '',
      estimated_duration: body.estimated_duration || '',
      assigned_date: body.assigned_date || new Date().toISOString(),
      company_name: 'Smart Trash Management System',
      app_link: 'https://your-app-link.com/tasks',
    }

    // Prepare EmailJS payload
    const emailjsPayload = {
      service_id: EMAILJS_SERVICE_ID,
      template_id: EMAILJS_TEMPLATE_ID,
      user_id: EMAILJS_PUBLIC_KEY,
      template_params: templateParams,
    }

    console.log('📧 Calling EmailJS API...')
    console.log('   Service:', EMAILJS_SERVICE_ID)
    console.log('   Template:', EMAILJS_TEMPLATE_ID)

    // Call EmailJS API with timeout
    const controller = new AbortController()
    const timeoutId = setTimeout(() => {
      controller.abort()
    }, 30000) // 30 second timeout

    try {
      const emailjsResponse = await fetch(EMAILJS_API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(emailjsPayload),
        signal: controller.signal,
      })

      clearTimeout(timeoutId)
      const responseData = await emailjsResponse.text()
      
      console.log('📧 EmailJS Response Status:', emailjsResponse.status)
      console.log('📧 EmailJS Response Body:', responseData)

      if (emailjsResponse.ok) {
        return new Response(
          JSON.stringify({ 
            success: true, 
            message: 'Email sent successfully',
            status: emailjsResponse.status,
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          },
        )
      } else {
        console.error('❌ EmailJS error:', responseData)
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: responseData || `EmailJS returned status ${emailjsResponse.status}`,
            status: emailjsResponse.status,
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: emailjsResponse.status,
          },
        )
      }
    } catch (fetchError) {
      clearTimeout(timeoutId)
      
      if (fetchError instanceof Error && fetchError.name === 'AbortError') {
        console.error('❌ EmailJS request timeout')
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: 'Request timeout - EmailJS API did not respond in time',
          }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 504,
          },
        )
      }
      
      console.error('❌ Fetch error:', fetchError)
      throw fetchError // Re-throw to be caught by outer catch
    }
  } catch (error) {
    console.error('❌ Error sending email:', error)
    const errorMessage = error instanceof Error ? error.message : String(error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: errorMessage || 'Unknown error occurred',
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
}

// Start the server
// @ts-ignore - serve is available in Deno runtime
serve(handleRequest)
