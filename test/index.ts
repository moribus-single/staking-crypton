import { expect } from "chai";
import { ethers } from "hardhat";

import { 
    Contract, 
    Signer, 
    BigNumber 
} from "ethers";

require('@openzeppelin/test-helpers/configure')({
    provider: 'http://localhost:8080',
});
import "@openzeppelin/test-helpers";
import { time } from "console";

describe("Staking", function () {
    const name: string = "KZ Token";
    const symbol: string = "KZT";
    const reward: number = 100;
    const epochDuration: number = 24;       // hours

    let contract: Contract;
    let token: Contract;
    let users: Signer[];

    beforeEach(async function () {
        const Factory = await ethers.getContractFactory("Token");
        token = await Factory.deploy(
            name,
            symbol
        );
        await token.deployed();

        const Factory1 = await ethers.getContractFactory("Staking");
        contract = await Factory1.deploy(
            token.address,
            reward,
            epochDuration
        );
        await contract.deployed();

        users = await ethers.getSigners();

        for(var i = 1; i < 5; i++){
            token.mint(
                await users[i].getAddress(),
                100000
            );
        }

        token.mint(
            contract.address,
            BigNumber.from("1000000000000000000000000")
        );

        await token.connect(users[1]).approve(
            contract.address,
            100000
        );
        await token.connect(users[2]).approve(
            contract.address,
            100000
        );
        await token.connect(users[3]).approve(
            contract.address,
            100000
        );
        await token.connect(users[4]).approve(
            contract.address,
            100000
        );
    });

    it("Staker #1", async function () {
        await contract.connect(users[1]).stake(1000);
        console.log("user1:");
        console.log(
            await contract.connect(users[1]).callStatic.getInfo()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.getInfo()
        );

        let user1 = await contract.connect(users[1]).callStatic.getInfo();
        expect(user1[2]).to.be.eq(0);   // missed = 0
        expect(user1[3]).to.be.eq(0);   // available = 0
        
        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(1000);

        await ethers.provider.send("evm_increaseTime", [86401]);     // 1 days
        await ethers.provider.send("evm_mine", []);
        

        console.log("\nEPOCH #1");
        await contract.connect(users[2]).stake(2000);

        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(3000);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #2");

        await contract.connect(users[3]).stake(2500);

        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(5500);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #3");
        await contract.connect(users[4]).stake(5000);

        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(10500);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #4");
        await contract.connect(users[1]).stake(1500);

        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(12000);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #5");
        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(12000);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #6");
        await contract.connect(users[2]).stake(5000);
        await contract.connect(users[3]).stake(1000);

        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(18000);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);  
        

        console.log("\nEPOCH #7");
        await contract.connect(users[4]).stake(30000);
        
        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(48000);
        
        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days 
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #8");        
        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(48000);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days 
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #9");
        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(48000);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days 
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #10");
        expect(
            (await contract.stakingInfo())[3]
        ).to.be.eq(48000);


        // CHECKING WITHDRAW

        // USER #1
        let beforeBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        await contract.connect(users[1]).claim();

        let afterBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        expect(
            afterBalance.sub(beforeBalance)
        ).to.be.eq("232");


        // USER #2    
        beforeBalance = await token.balanceOf(
            await users[2].getAddress()
        );

        await contract.connect(users[2]).claim();

        afterBalance = await token.balanceOf(
            await users[2].getAddress()
        );
        
        console.log(afterBalance, beforeBalance, afterBalance.sub(beforeBalance))
        expect(
            afterBalance.sub(beforeBalance)
        ).to.be.eq("238");

        
        // USER #3
        beforeBalance = await token.balanceOf(
            await users[3].getAddress()
        );

        await contract.connect(users[3]).claim();

        afterBalance = await token.balanceOf(
            await users[3].getAddress()
        );

        expect(
            afterBalance.sub(beforeBalance)
        ).to.be.eq("152")


        // USER #4
        beforeBalance = await token.balanceOf(
            await users[4].getAddress()
        );

        await contract.connect(users[4]).claim();

        afterBalance = await token.balanceOf(
            await users[4].getAddress()
        );

        expect(
            afterBalance.sub(beforeBalance)
        ).to.be.eq("377")
    });

    it("withdraw", async () => {
        let beforeBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        await contract.connect(users[1]).stake(1000);

        let afterBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        expect(
            beforeBalance.sub(afterBalance)
        ).to.be.eq(1000);

        await ethers.provider.send("evm_increaseTime", [86401]);     // 1 days 
        await ethers.provider.send("evm_mine", []);

        console.log("\nEPOCH #1");
        beforeBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        await contract.connect(users[1]).unstake(500)

        afterBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        expect(
            afterBalance.sub(beforeBalance)
        ).to.be.eq(500);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days 
        await ethers.provider.send("evm_mine", []);

        console.log("\nEPOCH #2");

        beforeBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        await contract.connect(users[1]).claim()

        afterBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        expect(
            afterBalance.sub(beforeBalance)
        ).to.be.eq(200)
    })
});
