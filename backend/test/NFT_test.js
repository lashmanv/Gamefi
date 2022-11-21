const { ethers } = require("hardhat");
const { expect } = require('chai')

  describe('NFT Unit Tests', async function () {
    let NFT;
    let alice;
    let bob;
    let carol;

    // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    // ['0xb7b19092bad498eae34230a9e14c8ce3d9d85b2bb91212108c9d47d1948acfeb','0x1f957db768cd7253fad82a8a30755840d536fb0ffca7c5c73fe9d815b1bc2f2f','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x58162bdb479db9dd8ec8b3e47602cbdc09fae924260d1938c976eec95da1f4b8']

    // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    // ['0xe9707d0e6171f728f7473c24cc0432a9b07eaaf1efed6a137a4a8c12c79552d9','0x23cc00f9327522794c39f632a2562a1d9282e3d3be7f5bf6007a8ca2849125e4','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x58162bdb479db9dd8ec8b3e47602cbdc09fae924260d1938c976eec95da1f4b8']

    // 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    // ['0xfbf9aaddb0b82e47f67bcafbecf7ca5d5e4f920dfef58fcc8be75b4f297eedeb','0x070e8db97b197cc0e4a1790c5e6c3667bab32d733db7f815fbe84f5824c7168d','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x58162bdb479db9dd8ec8b3e47602cbdc09fae924260d1938c976eec95da1f4b8']

    before(async () => {
      NFT = await ethers.getContractFactory("Nft")
  
      this.signers = await ethers.getSigners()
      alice = this.signers[0]
      bob = this.signers[1]
      carol = this.signers[2]
    })
  
    beforeEach(async () => {
      NFT = await NFT.deploy("ipfs://QmZvcBbTZXT2KPDNa8oWj2gaHaEmExvvrvKeeR1o7p7juL","0x5b7879adb5297db6f1d7cfd57c317229c136825f2ea2575d976b472fff662f7b")
      
      NFT.whitelistMint("['0xb7b19092bad498eae34230a9e14c8ce3d9d85b2bb91212108c9d47d1948acfeb','0x1f957db768cd7253fad82a8a30755840d536fb0ffca7c5c73fe9d815b1bc2f2f','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x58162bdb479db9dd8ec8b3e47602cbdc09fae924260d1938c976eec95da1f4b8']",alice.address)
      NFT.whitelistMint("['0xe9707d0e6171f728f7473c24cc0432a9b07eaaf1efed6a137a4a8c12c79552d9','0x23cc00f9327522794c39f632a2562a1d9282e3d3be7f5bf6007a8ca2849125e4','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x58162bdb479db9dd8ec8b3e47602cbdc09fae924260d1938c976eec95da1f4b8']",bob.address)
      NFT.whitelistMint("['0xfbf9aaddb0b82e47f67bcafbecf7ca5d5e4f920dfef58fcc8be75b4f297eedeb','0x070e8db97b197cc0e4a1790c5e6c3667bab32d733db7f815fbe84f5824c7168d','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x58162bdb479db9dd8ec8b3e47602cbdc09fae924260d1938c976eec95da1f4b8']",carol.address)
    })

    // it('should return the correct URI', async () => {
    //   let expectedURI = fs.readFileSync("./test/data/metadataBlueCircle.txt", "utf8")
    //   let uri = await NFT.tokenURI(0)
    //   console.log(expectedURI)
    //   console.log(uri)
    //   expect(uri == expectedURI).to.be.true
    // })
  
    it("should not allow to mint if not whitelisted", async () => {
      await expect (NFT.connect(bob).whitelistMint("['0xb7b19092bad498eae34230a9e14c8ce3d9d85b2bb91212108c9d47d1948acfeb','0x1f957db768cd7253fad82a8a30755840d536fb0ffca7c5c73fe9d815b1bc2f2f','0x924862b314bd38813a325167aca7caee16318f07303bd8e9f81bbe5808575fbf','0xe5076a139576746fd34a0fd9c21222dc274a909421fcbaa332a5af7272b6dcb1','0x148c730f8169681c1ebfb5626eb20af3d2351445463a1fdc5d0b116c62dc58c8','0x58162bdb479db9dd8ec8b3e47602cbdc09fae924260d1938c976eec95da1f4b8']",alice.address, { from: bob.address})).to.be.revertedWith("ERC20: transfer amount exceeds allowance")
      

      await this.sushi.approve(this.bar.address, "50")

      await expect(this.bar.enter("100")).to.be.revertedWith("ERC20: transfer amount exceeds allowance")
      await this.sushi.approve(this.bar.address, "100")
      await this.bar.enter("100")
      expect(await this.bar.balanceOf(this.alice.address)).to.equal("100")
    })
  
    it("should not allow to stake if not have enough approve", async function () {
      await expect(this.bar.enter("100")).to.be.revertedWith("ERC20: transfer amount exceeds allowance")
      await this.sushi.approve(this.bar.address, "50")
      await expect(this.bar.enter("100")).to.be.revertedWith("ERC20: transfer amount exceeds allowance")
      await this.sushi.approve(this.bar.address, "100")
      await this.bar.enter("100")
      expect(await this.bar.balanceOf(this.alice.address)).to.equal("100")
    })
  
    it("should not allow to withraw before 2 days", async function () {
      await this.sushi.approve(this.bar.address, "100")
      await this.bar.enter("100")
      await expect(this.bar.leave("25")).to.be.revertedWith("Cannot be unstaked before 2 days")
    })
  
    it("should not allow to withraw more than staked", async function () {
      await this.sushi.approve(this.bar.address, "100")
      await this.bar.enter("100")
      await ethers.provider.send('evm_increaseTime', [3*24*60*60]);
      await expect(this.bar.leave("26")).to.be.revertedWith("Invalid Amount");
    }) 
  
    it("should work with more than one participant", async function () {
      await this.sushi.approve(this.bar.address, "100000000000000000000")
      await this.sushi.connect(this.bob).transfer(this.bar.address, "100000000000000000000", { from: this.bob.address })
  
      // Alice enters and gets 100 shares
      await this.bar.enter("100000000000000000000")
  
      expect(await this.bar.balanceOf(this.alice.address)).to.equal("100000000000000000000")
      expect(await this.sushi.balanceOf(this.bar.address)).to.equal("200000000000000000000")
  
      /* ---------------------------------------------------------------------------------------------------------------------- */
  
      await this.sushi.connect(this.carol).approve(this.bar.address, "100000000000000000000", { from: this.carol.address })
  
      await this.bar.connect(this.carol).enter("100000000000000000000", { from: this.carol.address })
  
      expect(await this.sushi.balanceOf(this.bar.address)).to.equal("300000000000000000000")
  
      await ethers.provider.send('evm_increaseTime', [2*24*60*60]);
  
      // Bob withdraws 25 shares. He should receive 25*60/36 = 8 shares
      await this.bar.leave("25000000000000000000")
  
      // Carol withdraws 25 shares. He should receive 25*60/36 = 8 shares
      await this.bar.connect(this.carol).leave("25000000000000000000", { from: this.carol.address })
  
      expect(await this.sushi.balanceOf(this.alice.address)).to.equal("31250000000000000000");
  
      expect(await this.sushi.balanceOf(this.carol.address)).to.equal("35000000000000000000");
  
      expect(await this.sushi.balanceOf(this.bar.address)).to.equal("233750000000000000000")
    })
  
  })