// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('Edge Function 시작')
    console.log('요청 헤더:', Object.fromEntries(req.headers.entries()))
    
    // Create a Supabase client with the Auth context of the function
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get the user from the request
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      console.log('사용자 인증 실패:', userError)
      throw new Error('Unauthorized')
    }

    const userId = user.id
    console.log('사용자 ID:', userId)

    // Delete user data in order
    const { error: milestonesError } = await supabaseClient
      .from('user_milestones')
      .delete()
      .eq('user_id', userId)

    if (milestonesError) {
      console.error('Error deleting milestones:', milestonesError)
    }

    const { error: prioritiesError } = await supabaseClient
      .from('user_stat_priorities')
      .delete()
      .eq('user_id', userId)

    if (prioritiesError) {
      console.error('Error deleting priorities:', prioritiesError)
    }

    const { error: skillsError } = await supabaseClient
      .from('skills')
      .delete()
      .eq('user_id', userId)

    if (skillsError) {
      console.error('Error deleting skills:', skillsError)
    }

    const { error: questsError } = await supabaseClient
      .from('quests')
      .delete()
      .eq('user_id', userId)

    if (questsError) {
      console.error('Error deleting quests:', questsError)
    }

    const { error: profileError } = await supabaseClient
      .from('profiles')
      .delete()
      .eq('id', userId)

    if (profileError) {
      console.error('Error deleting profile:', profileError)
    }

    // Delete the user account
    console.log('Attempting to delete user account:', userId)
    const { error: deleteUserError } = await supabaseClient.auth.admin.deleteUser(userId)

    if (deleteUserError) {
      console.error('Failed to delete user:', deleteUserError)
      throw new Error(`Failed to delete user: ${deleteUserError.message}`)
    }

    console.log('User account deleted successfully')

    return new Response(
      JSON.stringify({ message: 'User account deleted successfully' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
