import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import AttendanceNFT from "../contracts/AttendanceNFT.cdc"
import MetadataViews from "../contracts/MetadataViews.cdc"
import FungibleToken from "../contracts/utility/FungibleToken.cdc"

/// This script uses the NFTMinter resource to mint a new NFT
/// It must be run with the account that has the minter resource
/// stored in /storage/NFTMinter

transaction {

    /// local variable for storing the minter reference
    let location: &AttendanceNFT.Location

    /// Reference to the receiver's collection
    let recipientCollectionRef: &{NonFungibleToken.CollectionPublic}

    /// Previous NFT ID before the transaction executes
    let mintingIDBefore: UInt64

    prepare(locationAcct: AuthAccount, receiverAcct: AuthAccount) {
        self.mintingIDBefore = AttendanceNFT.totalSupply

        // borrow a reference to the NFTMinter resource in storage
        self.location = locationAcct.borrow<&AttendanceNFT.Location>(from: AttendanceNFT.LocationStoragePath)
            ?? panic("Account does not store an object at the specified path")

        // Borrow the recipient's public NFT collection reference
        self.recipientCollectionRef = receiverAcct
            .getCapability(AttendanceNFT.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        // Mint the NFT and deposit it to the recipient's collection
        self.location.mintNFT(
            recipient: self.recipientCollectionRef
        )
    }

    post {
        self.recipientCollectionRef.getIDs().contains(self.mintingIDBefore): "The next NFT ID should have been minted and delivered"
        AttendanceNFT.totalSupply == self.mintingIDBefore + 1: "The total supply should have been increased by 1"
    }
}
 