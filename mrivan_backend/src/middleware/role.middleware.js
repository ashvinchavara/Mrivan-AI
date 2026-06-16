/**
 * Middleware to restrict route access to specific user roles.
 * Must be placed after the authenticate middleware.
 * 
 * @param {Array<string>} allowedRoles - List of roles permitted to access this endpoint
 */
const authorize = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized: User context not found' });
    }

    const userRole = req.user.role;

    if (!userRole || !allowedRoles.includes(userRole)) {
      return res.status(403).json({ 
        error: `Forbidden: Access denied. Required role(s): [${allowedRoles.join(', ')}]. Current role: '${userRole || 'none'}'` 
      });
    }

    next();
  };
};

module.exports = {
  authorize,
};
