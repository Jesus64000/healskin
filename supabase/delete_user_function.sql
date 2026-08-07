-- ============================================================================
-- 🗑️ FUNCIÓN PARA BORRADO FÍSICO DE USUARIOS EN SUPABASE AUTH Y PROFILES
-- Pega este código en el SQL Editor de tu Supabase Dashboard y presiona RUN.
-- ============================================================================

CREATE OR REPLACE FUNCTION delete_user_by_admin(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Borrar datos dependientes de las tablas públicas
  DELETE FROM public.ai_scans WHERE patient_id = target_user_id;
  DELETE FROM public.skin_evolution WHERE user_id = target_user_id;
  DELETE FROM public.appointments WHERE patient_id = target_user_id OR doctor_id = target_user_id;
  DELETE FROM public.medical_notes WHERE patient_id = target_user_id OR doctor_id = target_user_id;
  DELETE FROM public.chat_messages WHERE sender_id = target_user_id OR receiver_id = target_user_id;
  DELETE FROM public.patient_procedures WHERE patient_id = target_user_id;
  
  -- 2. Borrar del perfil público
  DELETE FROM public.profiles WHERE id = target_user_id;
  
  -- 3. Borrar de la tabla de autenticación de Supabase (Libera el e-mail 100%)
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;
