/*
  # Fix Security Issues

  1. Security Fixes
    - Drop unused indexes on content_posts table (idx_content_posts_content_type and idx_content_posts_status)
    - Fix search_path vulnerability in update_updated_at_column function by making it immutable with explicit schema reference

  2. Notes
    - Unused indexes consume storage and slow down INSERT/UPDATE operations without providing query benefits
    - Function search_path vulnerability fixed by using explicit schema qualification and SECURITY DEFINER with proper search_path
*/

-- Drop unused indexes
DROP INDEX IF EXISTS idx_content_posts_content_type;
DROP INDEX IF EXISTS idx_content_posts_status;

-- Fix the update_updated_at_column function to have immutable search_path
-- First drop the existing function
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- Recreate with proper security settings
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Recreate the trigger on content_posts if it exists
DROP TRIGGER IF EXISTS update_content_posts_updated_at ON public.content_posts;

CREATE TRIGGER update_content_posts_updated_at
  BEFORE UPDATE ON public.content_posts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
