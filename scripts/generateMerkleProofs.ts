import { readFileSync, writeFileSync } from "fs";
import { generateMerkleTree, getProof } from "../lib/proof";

// build merkle tree
const addresses: string[] = JSON.parse(
	readFileSync(`${__dirname}/../snapshot.json`, "utf-8")
);
const tree = generateMerkleTree(addresses);
const rootValue = tree.getHexRoot();
console.log("Merkle root:", rootValue);

// get a sample proof
const sampleAddr = "0x3998f3C697300e0e4264Dea9f2dD76e1F8c73bdD"; // sha.eth
console.log("Sample proof:", getProof(tree, sampleAddr));

// write proofs out
const addressProofMap = Object.fromEntries(
	addresses.map((addr) => [addr, getProof(tree, addr)])
);
writeFileSync("proofs.json", JSON.stringify(addressProofMap));
