import React, { useState } from "react";
import {BrowserRouter as Router,Routes,Route,Link} from 'react-router-dom';

import logo from './icon.png'; 

import './App.css';

import Home from './pages/Home';
import Mint from './pages/Mint';
import Gallery from './pages/Gallery';
import MyTokens from './pages/MyTokens';

import Login from './components/Login';

function App() {

	const [web3props, setWeb3Props] = useState({ provider: null, signerAddress: null, contract: null });

	// Callback function for the Login component to give us access to the web3 instance and contract functions
	const OnLogin = function(param){
		let { provider, signerAddress, contract } = param;
		if(provider && signerAddress && signerAddress.length && contract){
			setWeb3Props({ provider, signerAddress, contract });
		}
	}

	// If the wallet is connected, all three values will be set. Use to display the main nav below.
	const contractAvailable = !(!web3props.provider && !web3props.signerAddress && !web3props.contract);
	// Grab the connected wallet address, if available, to pass into the Login component
	const walletAddress = web3props.signerAddress ? web3props.signerAddress[0] : "";

	return (
		<div className="App">
			<Router>
				<header>
					<Link to="/">
						<img id="logo" src={logo} alt={'token'}/>
					</Link>
					<nav>
						<ul>
								{contractAvailable && <>
									<li>
										<Link to="/mint">Mint</Link>
									</li>
									<li>
										<Link to="/gallery">Gallery</Link>
									</li>
									<li>
										<Link to="/mytokens">My Nfts</Link>
									</li>
								</>}
								<li>
									<Login callback={OnLogin} connected={contractAvailable} address={walletAddress}></Login>
								</li>
						</ul>
					</nav>
				</header>
				<div className="content">
					<Routes>
						<Route path="/mytokens" element={<MyTokens contract={web3props.contract} address={walletAddress} />} />
						<Route path="/gallery" element={<Gallery contract={web3props.contract} />} />
						<Route path="/mint" element={<Mint contract={web3props.contract} address={walletAddress} />} />	
						<Route path="/" element={<Home />} />
					</Routes>
				</div>
			</Router>
		</div>
	);
}

export default App;
