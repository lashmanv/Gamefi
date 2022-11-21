import React, {useState} from "react";

export default function Gallery(props) {
	const [tokenURIs, setTokenURIs] = useState([]);
	const [error, setError] = useState(true);

	// Populate the setTokenURIs variable with token URIs belonging to the curent wallet address.
	const GetTokenURIs = async () => {
		let tokens = [];
		// Taking advantage of the fact that token IDs are an auto-incrementing integer starting with 1.
		// Starting with userTokens and counting down to 1 gives us the tokens in order of most recent.
		for(let idx=1; idx <= 50; idx++){
			try{			

				// Fetch the json metadata the token points to.
				let response = await fetch("https://ipfs.moralis.io:2053/ipfs/QmZvcBbTZXT2KPDNa8oWj2gaHaEmExvvrvKeeR1o7p7juL/"+idx+".json");

				// Add the image url if available in the metadata.
				let metaData = await response.json();

				let res = metaData.image;

				let img=(res.replace("ipfs://", ""))				

				// Fetch the json metadata the token points to.
				let final = await fetch("https://ipfs.moralis.io:2053/ipfs/"+img);
				// console.log(final);

				// Add the image url if available in the metadata.
				
				if(final.ok) 
					tokens.push(final.url);
					console.log(tokens.length);

			}catch(e){
				// Either the contract call or the fetch can fail. You'll want to handle that in production.
				console.log('Error occurred while fetching metadata.')
				continue;
			}
		}

		// Update the list of available asset URIs
		if(tokens.length) setTokenURIs([...tokens]);
	};

	// Handle contract unavailable. 
	// This is an extra precaution since the user shouldn't be able to get to this page without connecting.
	if(!props.contract) return (<div className="page error">Contract Not Available</div>);

	// Set up the list of available token URIs when the component mounts.
	if(!tokenURIs.length) GetTokenURIs();

	// Display the personal token gallery
	return (
		<div>

		<h2>Gallery</h2>
		<div style={{display: 'inline-block',justifyContent:'center'}}>
			{tokenURIs.map((uri, idx) => (
				<div key={idx}>
				<br></br>
				<div style={{ margin: '50px',borderRadius:'50px',width: '95%',alignContent:'center' ,backgroundColor: 'white'}} >
					<br/>
					<h2 style={{color:'black'}}>Nft Id: {idx}</h2>
					<img src={uri} alt={'token '+idx} width="300" height="500"/>
				</div>
				</div>
			))}
		</div>
		</div>
		
	);
}