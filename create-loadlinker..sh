#!/bin/bash

echo "🚀 Creating LoadLinker Professional MVP..."

PROJECT="loadlinker"
mkdir -p $PROJECT
cd $PROJECT

# -------------------------
# Folder Structure
# -------------------------
mkdir -p backend/{config,models,routes,controllers,middleware,utils}
mkdir -p frontend
mkdir -p docs

# =========================
# BACKEND
# =========================

cat > backend/package.json << 'EOF'
{
  "name": "loadlinker-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "dev": "nodemon server.js",
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.5.0",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.7.0",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

# -------------------------
# SERVER
# -------------------------

cat > backend/server.js << 'EOF'
require('dotenv').config()
const express = require('express')
const mongoose = require('mongoose')
const cors = require('cors')
const helmet = require('helmet')
const rateLimit = require('express-rate-limit')

const app = express()

// Security
app.use(helmet())
app.use(cors())
app.use(express.json())

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
}))

// DB
mongoose.connect(process.env.MONGO_URI)
.then(()=>console.log("MongoDB Connected"))
.catch(err=>console.log(err))

// Routes
app.use('/api/auth', require('./routes/auth'))
app.use('/api/load', require('./routes/load'))

// Error handler
app.use((err, req, res, next)=>{
  res.status(500).json({error: err.message})
})

const PORT = process.env.PORT || 5000
app.listen(PORT, ()=>console.log(`Server running on ${PORT}`))
EOF

# -------------------------
# ENV
# -------------------------

cat > backend/.env << 'EOF'
PORT=5000
MONGO_URI=mongodb://localhost:27017/loadlinker
JWT_SECRET=super_secret_key_change_this
EOF

# -------------------------
# USER MODEL
# -------------------------

cat > backend/models/User.js << 'EOF'
const mongoose = require('mongoose')

const schema = new mongoose.Schema({
  phone: { type: String, unique: true },
  role: { type: String, enum:['shipper','truckOwner','admin'] },
  otp: String,
  otpExpiry: Date,
  wallet: { type:Number, default:0 }
})

module.exports = mongoose.model('User', schema)
EOF

# -------------------------
# AUTH ROUTE
# -------------------------

cat > backend/routes/auth.js << 'EOF'
const router = require('express').Router()
const jwt = require('jsonwebtoken')
const User = require('../models/User')

router.post('/send-otp', async (req,res)=>{
  const { phone } = req.body
  const otp = Math.floor(100000 + Math.random()*900000).toString()

  const user = await User.findOneAndUpdate(
    { phone },
    { otp, otpExpiry: Date.now()+5*60*1000 },
    { upsert:true, new:true }
  )

  res.json({ message:"OTP sent (dev mode)", otp })
})

router.post('/verify-otp', async (req,res)=>{
  const { phone, otp, role } = req.body
  const user = await User.findOne({ phone })

  if(!user || user.otp !== otp || user.otpExpiry < Date.now())
    return res.status(400).json({ error:"Invalid OTP" })

  if(!user.role && role) user.role = role
  await user.save()

  const token = jwt.sign({id:user._id, role:user.role}, process.env.JWT_SECRET)

  res.json({ token })
})

module.exports = router
EOF

# -------------------------
# LOAD MODEL
# -------------------------

cat > backend/models/Load.js << 'EOF'
const mongoose = require('mongoose')

const schema = new mongoose.Schema({
  shipperId: mongoose.Schema.Types.ObjectId,
  pickup: String,
  drop: String,
  amount: Number,
  status: { type:String, default:"open" }
})

module.exports = mongoose.model('Load', schema)
EOF

# -------------------------
# LOAD ROUTE
# -------------------------

cat > backend/routes/load.js << 'EOF'
const router = require('express').Router()
const Load = require('../models/Load')

router.post('/', async (req,res)=>{
  const load = await Load.create(req.body)
  res.json(load)
})

router.get('/', async (req,res)=>{
  const loads = await Load.find()
  res.json(loads)
})

module.exports = router
EOF

# -------------------------
# README
# -------------------------

cat > README.md << 'EOF'
# LoadLinker MVP

## Setup

cd backend
npm install
npm run dev

Server runs on http://localhost:5000
EOF

echo "✅ LoadLinker MVP Created Successfully!"