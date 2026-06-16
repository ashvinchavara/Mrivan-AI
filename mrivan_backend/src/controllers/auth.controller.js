const { supabaseAdmin } = require('../config/db');

/**
 * Syncs the authenticated Supabase Auth user with the public profiles table.
 * Created/Updates profile settings like role, school_id, and full name.
 */
const syncProfile = async (req, res, next) => {
  try {
    const user = req.user; // Set by authenticate middleware
    const { fullName, role, schoolId } = req.body;

    if (!supabaseAdmin) {
      return res.status(500).json({ error: 'Supabase admin client not initialized' });
    }

    // Retrieve the existing profile
    const { data: existingProfile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    let finalProfile;

    if (existingProfile) {
      // Update profile
      const { data, error } = await supabaseAdmin
        .from('profiles')
        .update({
          full_name: fullName || existingProfile.full_name,
          role: role || existingProfile.role,
          school_id: schoolId || existingProfile.school_id,
        })
        .eq('id', user.id)
        .select()
        .single();

      if (error) throw error;
      finalProfile = data;
    } else {
      // Create new profile
      const { data, error } = await supabaseAdmin
        .from('profiles')
        .insert({
          id: user.id,
          full_name: fullName || user.email.split('@')[0],
          role: role || 'student', // Default to student
          school_id: schoolId || null,
        })
        .select()
        .single();

      if (error) throw error;
      finalProfile = data;
    }

    res.json({
      message: 'Profile synchronized successfully',
      profile: finalProfile
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  syncProfile,
};
