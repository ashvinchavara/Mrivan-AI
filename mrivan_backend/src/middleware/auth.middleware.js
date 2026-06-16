const { supabase } = require('../config/db');

/**
 * Middleware to verify Supabase JWT token from Authorization header.
 * Attaches the authenticated user object to the request object.
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Access token missing or malformed' });
    }

    const token = authHeader.split(' ')[1];
    
    // Call Supabase API to fetch current user session details using the JWT token
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ error: 'Unauthorized: Invalid or expired token' });
    }

    // Retrieve user profile to check custom roles and details
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileError || !profile) {
      // If profile doesn't exist, attach user info with null role (fallback)
      req.user = {
        id: user.id,
        email: user.email,
        role: null,
        fullName: null,
        schoolId: null
      };
    } else {
      req.user = {
        id: user.id,
        email: user.email,
        role: profile.role,
        fullName: profile.full_name,
        schoolId: profile.school_id,
        parentId: profile.parent_id,
        classId: profile.class_id
      };
    }

    next();
  } catch (err) {
    next(err);
  }
};

module.exports = {
  authenticate,
};
