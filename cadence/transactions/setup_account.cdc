import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import AttendanceNFT from "../contracts/AttendanceNFT.cdc"
import MetadataViews from "../contracts/MetadataViews.cdc"

/// This transaction is what an account would run
/// to set itself up to receive NFTs

transaction {

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&AttendanceNFT.Collection>(from: AttendanceNFT.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- AttendanceNFT.createEmptyCollection()

        // save it to the account
        signer.save(<-collection, to: AttendanceNFT.CollectionStoragePath)

        // create a public capability for the collection
        signer.link<&{NonFungibleToken.CollectionPublic, AttendanceNFT.AttendanceNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            AttendanceNFT.CollectionPublicPath,
            target: AttendanceNFT.CollectionStoragePath
        )
    }
}
