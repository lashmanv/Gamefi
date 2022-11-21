import React, {useState} from "react";

export default function MyTokens(props) {
	const [totalSupply, setTotalSupply] = useState(null);
	const [tokenURIs, setTokenURIs] = useState([]);
	const [error, setError] = useState(true);
	// Populate userTokens with an array of token IDs belonging to the curent wallet address.
	const GetTotalSupply = async () => {
		if(!props || !props.contract) return;
		try{
		const transaction = await props.contract.totalSupply();
        await transaction.wait;
        setTotalSupply(parseInt(transaction._hex));
      	} catch (error) {
        setError(error);
		console.log(error);
      }
	};

	// Populate the setTokenURIs variable with token URIs belonging to the curent wallet address.
	const GetTokenURIs = async (totalSupply) => {
		if(!totalSupply) return;
		let tokens = [];
		// Taking advantage of the fact that token IDs are an auto-incrementing integer starting with 1.
		// Starting with userTokens and counting down to 1 gives us the tokens in order of most recent.
		for(let idx=0; idx < totalSupply; idx++){
			try{
				let owner = await props.contract.ownerOf(idx);
				await owner.wait;
				
				if(owner === props.address) {
					// Get the metadata URI associated with the token.
					let tokenURI = await props.contract.tokenURI(idx);
					await tokenURI.wait;
					let meta=tokenURI.replace("ipfs://", "")	

					// Fetch the json metadata the token points to.
					let response = await fetch("https://ipfs.moralis.io:2053/ipfs/"+meta);
					await response.wait;
					let metaData = await response.json();

					let res = metaData.image;
					
					let img=(res.replace("ipfs://", ""))	
					
					// Fetch the json metadata the token points to.
					let final = await fetch("https://ipfs.moralis.io:2053/ipfs/"+img);

				// Add the image url if available in the metadata.
					if(final.ok) {
						tokens.push(final.url);
						console.log(tokens.length);
					}
				}
				else{
					continue;
				}

			}catch(e){
				// Either the contract call or the fetch can fail. You'll want to handle that in production.
				console.log('Error occurred while fetching metadata.')
				continue;
			}
		}

		// Update the list of available asset URIs
		if(tokens.length) setTokenURIs([...tokens]);
		console.log(tokenURIs);
	};

	// Handle contract unavailable. 
	// This is an extra precaution since the user shouldn't be able to get to this page without connecting.
	if(!props.contract) return (<div className="page error">Contract Not Available</div>);

	// Get all token IDs associated with the wallet address when the component mounts.
	if(!totalSupply) GetTotalSupply();

	// Set up the list of available token URIs when the component mounts.
	if(totalSupply && !tokenURIs.length) GetTokenURIs(totalSupply);

	// Display the personal token gallery
	return (
		<div>
		{error ? (
			<span>{error?.data?.message || error?.message}</span>
		) : null}

		<h2>User Assests</h2>
		<div style={{display:'flex', justifyContent:'center'}}>
			{tokenURIs.map((uri, idx) => (
				<div key={idx}>
				<br></br>
				<div style={{ margin: '50px',borderRadius:'50px',width: '90%',alignContent:'center' ,backgroundColor: 'white'}} >
					<br/>
					<h2 style={{color:'black'}}>Nft Id: {idx}</h2>
					<img src={uri} alt={'token '+idx} width="300" height="500"/>
					<br></br>
				</div>
				</div>
			))}
		</div>
		</div>
		
	);
}