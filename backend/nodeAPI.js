const ethers = require('ethers');

const app = require('express')();

const PORT = 4000;

app.listen(PORT,() => console.log(`server is running on ${PORT}`));

app.get('/get', (req, res) => {
    res.send("Get Request")
})

const MNEMONIC = process.env.MNEMONIC
const CONTRACT_ADDRESS = '0xC5d1E3258683d214c3753D20C48E7c846FB55e1c'
const ABI = [
    'function ownerOf(uint256 tokenId) public view returns (address)'
]

app.get('/check/:nftId/:owner', async (req, res) => {
    const provider = ethers.getDefaultProvider('goerli')
    const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider)
    try {
        const value = await contract.ownerOf(req.params.nftId)
        if(value == req.params.owner) {
            res.send({"status":true})
        }
        else {
            res.send({"status":false})
        }
        
    } catch (e) {
        res.send(e)
    }
})

app.get('/check/:nftId', async (req, res) => {
    const provider = ethers.getDefaultProvider('goerli')
    const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider)
    try {
        const value = await contract.ownerOf(req.params.nftId)
        
        res.send(value)
        
        
    } catch (e) {
        res.send(e)
    }
})