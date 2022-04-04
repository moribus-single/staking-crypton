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
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        let user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[2]).to.be.eq(0);   // missed = 0
        expect(user1[3]).to.be.eq(0);   // available = 0
        
        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(1000);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(0)

        await ethers.provider.send("evm_increaseTime", [86401]);     // 1 days
        await ethers.provider.send("evm_mine", []);
        

        console.log("\nEPOCH #1");
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from(10).pow(17));
        console.log("user1")
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
    
        expect(user1[1]).to.be.eq(0);                                         // missed = 0
        expect(user1[3]).to.be.eq(BigNumber.from("100"));   // available = 0.1

        await contract.connect(users[2]).stake(2000);

        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(3000);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from(10).pow(17));

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #2");
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[2]).to.be.eq(0);                                         // missed = 0
        expect(user1[3]).to.be.eq(BigNumber.from("133"));   // available = 0.13333333333

        await contract.connect(users[3]).stake(2500);

        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(5500);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("133333333333333333"));

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #3");
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[2]).to.be.eq(0);                                         // missed = 0
        expect(user1[3]).to.be.eq(BigNumber.from("151"));   // available = 0.151515151515151

        await contract.connect(users[4]).stake(5000);

        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(10500);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("151515151515151514"));

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #4");
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[2]).to.be.eq(0);                                         // missed = 0
        expect(user1[3]).to.be.eq(BigNumber.from("161"));   // available = 0.16103896103896103

        await contract.connect(users[1]).stake(1500);

        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(12000);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("161038961038961037"));

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #5");
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[1]).to.be.eq(BigNumber.from("227272727272727271000"));   // missed = 0.227272727272727271000
        expect(user1[3]).to.be.eq(BigNumber.from("196"));   // available = 0.196158008658008654000

        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(12000);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("169372294372294370")); 

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #6");
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[1]).to.be.eq(BigNumber.from("227272727272727271000"));   // missed = 0.227272727272727271000
        expect(user1[3]).to.be.eq(BigNumber.from("216"));   // available = 0.216991341991341986500

        await contract.connect(users[2]).stake(5000);
        await contract.connect(users[3]).stake(1000);

        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(18000);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("177705627705627703"));

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days
        await ethers.provider.send("evm_mine", []);  
        

        console.log("\nEPOCH #7");
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[1]).to.be.eq(BigNumber.from("227272727272727271000"));   // missed = 0.227272727272727271000
        expect(user1[3]).to.be.eq(BigNumber.from("230"));   // available = 0.230880230880230874000

        await contract.connect(users[4]).stake(30000);
        
        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(48000);
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("183261183261183258"));
        
        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days 
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #8");
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[1]).to.be.eq(BigNumber.from("227272727272727271000"));   // missed = 0.227272727272727271000
        expect(user1[3]).to.be.eq(BigNumber.from("236"));   // available = 0.236088564213564206500
        
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("185344516594516591"));
        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(48000);

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days 
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #9");
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("187427849927849924"));

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[1]).to.be.eq(BigNumber.from("227272727272727271000"));   // missed = 0.227272727272727271000
        expect(user1[3]).to.be.eq(BigNumber.from("241"));   // available = 0.241296897546897539000
        
        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(48000);

        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        await ethers.provider.send("evm_increaseTime", [86400]);     // 1 days 
        await ethers.provider.send("evm_mine", []);


        console.log("\nEPOCH #10");
        expect(
            await contract.callStatic.TPS()
        ).to.be.eq(BigNumber.from("189511183261183258"));
        
        console.log(
            await contract.connect(users[1]).callStatic.user()
        );
        console.log("user2");
        console.log(
            await contract.connect(users[2]).callStatic.user()
        );

        user1 = await contract.connect(users[1]).callStatic.user();
        expect(user1[1]).to.be.eq(BigNumber.from("227272727272727271000"));   // missed = 0.227272727272727271000
        expect(user1[3]).to.be.eq(BigNumber.from("246"));   // available = 0.246505230880230871500

        expect(
            (await contract.stakingInfo())[4]
        ).to.be.eq(48000);


        // CHECKING WITHDRAW
        let beforeBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        await contract.connect(users[1]).withdraw();

        let afterBalance = await token.balanceOf(
            await users[1].getAddress()
        );

        expect(
            afterBalance.sub(beforeBalance).eq(
                BigNumber.from("246")
            )
        ).to.be.true;


        console.log("User2 withdraw");
            
        beforeBalance = await token.balanceOf(
            await users[2].getAddress()
        );

        await contract.connect(users[2]).withdraw();

        afterBalance = await token.balanceOf(
            await users[2].getAddress()
        );
        
        console.log(afterBalance, beforeBalance, afterBalance.sub(beforeBalance))
        expect(
            afterBalance.sub(beforeBalance).eq(
                BigNumber.from("246505230880230871500")
            )
        ).to.be.true;

        const user2 = await contract.connect(users[2]).callStatic.user();
        expect(user2[2]).to.be.eq(BigNumber.from("10885281"));   // missed = 0.227272727272727271000
        expect(user2[3]).to.be.eq(BigNumber.from("238"));   // available = 0.246505230880230871500
    });

    it("withdraw", async () => {
        
    })
});
