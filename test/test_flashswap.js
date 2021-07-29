const BN = require ('bn.js');
const { ethers } = require('hardhat');
const { expect } = require('chai');

require('dotenv').config();

describe('Flashswap_Uniswap', async () => {

    let owner, notOwner, balance, flashswap_uniswap , Dai, signer_dai_whale

    const DAI = '0x6B175474E89094C44Da98b954EedeAC495271d0F';  
    const DAI_WHALE = process.env.DAI_WHALE;
    const DAI_BORROW_AMOUNT = ethers.utils.parseEther('100000')
    const provider = new ethers.getDefaultProvider();

    beforeEach(async () => {
        [owner, notOwner] = await ethers.getSigners();

        const Flashswap_uniswap = await ethers.getContractFactory('Flashswap_uniswap');
        flashswap_uniswap = await Flashswap_uniswap.deploy();
        await flashswap_uniswap.deployed();

        expect(await flashswap_uniswap.owner()).to.equal(owner.address);

        Dai = await ethers.getContractAt('IERC20', DAI);

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [DAI_WHALE],
        });

        signer_dai_whale = await ethers.provider.getSigner(DAI_WHALE);

        balance = await Dai.balanceOf(DAI_WHALE);
        console.log(`dai balance of DAI WHALE is: ${ethers.utils.formatEther(balance)}`);
    })

    it('flashswap should work correctly', async () => {

        balance = await Dai.balanceOf(owner.address);
        console.log(`owner has Dai balance of: ${ethers.utils.formatEther(balance)}`);
        console.log('sending some DAI to owner...\n')   

        await Dai.connect(signer_dai_whale).transfer(
            flashswap_uniswap.address,
            ethers.utils.parseEther('1000000')
        )

        const send_ether = await signer_dai_whale.sendTransaction({
            to: owner.address,
            value: ethers.utils.parseEther("0.2")
        })

        send_ether.wait();

        balance = await provider.getBalance(owner.address);
        console.log(`eth balance of owner is: ${ethers.utils.formatEther(balance)}`);

        balance = await Dai.balanceOf(owner.address);
        console.log(`owner has Dai balance of: ${ethers.utils.formatEther(balance)}`);

        const tx = await flashswap_uniswap.flashswap(DAI, DAI_BORROW_AMOUNT);

        let event_logs = provider.getLogs({address: flashswap_uniswap.address, fromBlock: 0});
        
        event_logs.then(events => {
            console.log(events)
        })
    })
})

