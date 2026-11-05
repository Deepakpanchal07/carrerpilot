const jwt  = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ 
                success: false,
                message: 'No token provided, authorization denied'
            });
        }
        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.id).select('-password');
        if (!user) {
            return res.status(401).json({ 
                success: false,
                message: 'User not found, authorization denied'
            });
        }
        req.user = user;
        next();
    }catch (error) {
        return res.status(401).json({ 
            success: false,
            message: 'Token is not valid'
        });
    }
};

module.exports = { protect };