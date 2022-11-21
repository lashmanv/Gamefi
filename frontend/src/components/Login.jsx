import React from "react";
import { ethers } from "ethers";

import NFT from "../artifacts/contracts/NFT.sol/Nft.json";

export default function Login(props) {
	const TokenAddress = "0x9027b5f491496Fa658D534b82F61Aa7df05d1a68";
	
	const DoConnect = async () => {
		console.log('Connecting....');
		try {
			// Get network provider and web3 instance.	
			const provider = new ethers.providers.Web3Provider(window.ethereum);
			await window.ethereum.request({method: "eth_requestAccounts"});
			// Use web3 to get the user's accounts.
			const signer = provider.getSigner();
			let signerAddress = await signer.getAddress();
			signerAddress = [`${signerAddress}`];
			console.log(signerAddress);
			
			// Get an instance of the contract sop we can call our contract functions
			const contract = new ethers.Contract(TokenAddress, NFT, signer);
			props.callback({ provider, signerAddress, contract});

		} catch (error) {
			// Catch any errors for any of the above operations.
			console.error("Could not connect to wallet.", error);
		}
	};

	// If not connected, display the connect button.
	if(!props.connected) return <button className="login" onClick={DoConnect}>Connect Wallet</button>;

	// Display the wallet address. Truncate it to save space.
	return <button className="login">{props.address.slice(0,12)}...</button>;
}