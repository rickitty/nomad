const express=require('express');
const router = express.Router();
const axios = require("axios");

router.post("/create-market", async (req,res)=>{
    try{
        const {token, ...marketData}=req.body;

        if(!token){
            return res.status(400).json({error:"Bearer token is required"});
        }

        const responce=await axios.post(
            "https://qyzylorda-idm-test.curs.kz/api/v1/monitoring/market/create",
            marketData,
            {
                headers:{
                    Authorization: `Bearer ${token}`,
                    "Content-Type":"application/json"
                },
            }
        );

        res.json(responce.data);
    }catch(e){
        console.error(e.responce?.data||e.message);
        res.status(500).json({error:e.response?.data||e.message});
    }
});

router.get("/markets", async (req, res) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(400).json({ error: "Bearer token is required" });
        }

        const token = authHeader.replace("Bearer ", "");

        const response = await axios.get(
            "https://qyzylorda-idm-test.curs.kz/api/v1/monitoring/markets",
            {
                headers: {
                    Authorization: `Bearer ${token}`,
                },
            }
        );

        res.json(response.data);
    } catch (e) {
        console.error(e.response?.data || e.message);
        res.status(500).json({ error: e.response?.data || e.message });
    }
});


module.exports = router;