 /* 
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*   
*/

import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"

pub contract AttendanceNFT: NonFungibleToken, ViewResolver {

    /// Total supply of AttendanceNFTs in existence
    pub var totalSupply: UInt64

    // Total number of minters/locations in existence
    pub var totalLocations: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let LocationStoragePath: StoragePath
    pub let LocationPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let MinterPublicPath: PublicPath

    pub let locations: {UInt64: Address}

    /// The core resource that represents a Non Fungible Token. 
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        /// The unique ID that each NFT has
        pub let id: UInt64
        pub let locationId: UInt64

        /// Metadata fields
        pub let createdTimestamp: UFix64
    
        init(
            id: UInt64,
            locationId: UInt64
        ) {
            self.id = id
            self.locationId = locationId
            self.createdTimestamp = getCurrentBlock().timestamp
        }

        pub fun getLocation(): &Location {
            let wrapper = getAccount(AttendanceNFT.locations[self.locationId] ?? panic ("Location does not exist")).getCapability(AttendanceNFT.LocationPublicPath).borrow<&LocationWrapper>() ?? panic("Cannot borrow location at this address")
            return wrapper.borrowLocation()
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    let location = self.getLocation()
                    return MetadataViews.Display(
                        name: location.name,
                        description: location.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: location.thumbnail
                        )
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: AttendanceNFT.CollectionStoragePath,
                        publicPath: AttendanceNFT.CollectionPublicPath,
                        providerPath: /private/attendanceNFTCollection,
                        publicCollection: Type<&AttendanceNFT.Collection{AttendanceNFT.AttendanceNFTCollectionPublic}>(),
                        publicLinkedType: Type<&AttendanceNFT.Collection{AttendanceNFT.AttendanceNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&AttendanceNFT.Collection{AttendanceNFT.AttendanceNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-AttendanceNFT.createEmptyCollection()
                        })
                    )
            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface AttendanceNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowAttendanceNFT(id: UInt64): &AttendanceNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow AttendanceNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: AttendanceNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        /// 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @AttendanceNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///        
        pub fun borrowAttendanceNFT(id: UInt64): &AttendanceNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &AttendanceNFT.NFT
            }

            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let attendanceNFT = nft as! &AttendanceNFT.NFT
            return attendanceNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun createLocation(name: String, thumbnail: String, description: String): @Location {
        let location<- create Location(
            id: self.totalLocations,
            name: name,
            thumbnail: thumbnail,
            description: description
        )

        self.totalLocations = self.totalLocations + 1
        return <- location
    }

    pub resource LocationWrapper {
        access(self) var location: @Location?

        init() {
            self.location <- nil
        }

        access(account) fun setLocation(location: @Location) {
            pre {
                self.location == nil: "Location already set"
            }
            self.location <-! location
        }

        pub fun borrowLocation(): &Location {
            let ref = (&self.location as &Location?)!
            return ref
        }

        destroy() {
            destroy self.location
        }
    }

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    pub resource Location {
        pub let id: UInt64
        pub let name: String
        pub let thumbnail: String
        pub let description: String
        pub let createdTimestamp: UFix64

        pub var totalMinted: UInt64

        init(id: UInt64, name: String, thumbnail: String, description: String) {
            self.id = id
            self.name = name
            self.totalMinted = 0
            self.thumbnail = thumbnail
            self.description = description
            self.createdTimestamp = getCurrentBlock().timestamp
        }

        /// Mints a new NFT with a new ID and deposit it in the
        /// recipients collection using their collection reference
        ///
        /// @param recipient: A capability to the collection where the new NFT will be deposited
        /// @param name: The name for the NFT metadata
        /// @param description: The description for the NFT metadata
        /// @param thumbnail: The thumbnail for the NFT metadata
        ///     
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic}
        ) {
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address

            // create a new NFT
            var newNFT <- create NFT(
                id: AttendanceNFT.totalSupply,
                locationId: self.id
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            AttendanceNFT.totalSupply = AttendanceNFT.totalSupply + 1
            self.totalMinted = self.totalMinted + 1
        }
    }

    /// Mints a new NFT with a new ID and deposit it in the
    /// recipients collection using their collection reference
    ///
    /// @param recipient: A capability to the collection where the new NFT will be deposited
    /// @param name: The name for the NFT metadata
    /// @param description: The description for the NFT metadata
    /// @param thumbnail: The thumbnail for the NFT metadata
    ///     
    pub fun mintLocation(
        recipient: &LocationWrapper,
        name: String,
        description: String,
        thumbnail: String,
    ) {
        let metadata: {String: AnyStruct} = {}
        let currentBlock = getCurrentBlock()
        metadata["mintedBlock"] = currentBlock.height
        metadata["mintedTime"] = currentBlock.timestamp
        metadata["minter"] = recipient.owner!.address

        // this piece of metadata will be used to show embedding rarity into a trait
        metadata["foo"] = "bar"

        // create a new NFT
        var location <- create Location(
            id: AttendanceNFT.totalLocations,
            name: name,
            thumbnail: thumbnail,
            description: description,
        )

        // deposit it in the recipient's account using their reference
        recipient.setLocation(location: <-location)

        AttendanceNFT.totalLocations = AttendanceNFT.totalLocations + 1
    }

    pub fun createLocationWrapper(): @LocationWrapper {
        return <- create LocationWrapper()
    }

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: AttendanceNFT.CollectionStoragePath,
                    publicPath: AttendanceNFT.CollectionPublicPath,
                    providerPath: /private/attendanceNFT,
                    publicCollection: Type<&AttendanceNFT.Collection{AttendanceNFT.AttendanceNFTCollectionPublic}>(),
                    publicLinkedType: Type<&AttendanceNFT.Collection{AttendanceNFT.AttendanceNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&AttendanceNFT.Collection{AttendanceNFT.AttendanceNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-AttendanceNFT.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
        }
        return nil
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Initialize total locations
        self.totalLocations = 0

        // Initialize location accounts
        self.locations = {}

        // Set the named paths
        self.CollectionStoragePath = /storage/attendanceNFTCollection
        self.CollectionPublicPath = /public/attendanceNFTCollection
        self.LocationStoragePath = /storage/attendanceNFTLocation
        self.LocationPublicPath = /public/attendanceNFTLocation
        self.MinterStoragePath = /storage/attendanceNFTMinter
        self.MinterPublicPath = /public/attendanceNFTMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&AttendanceNFT.Collection{NonFungibleToken.CollectionPublic, AttendanceNFT.AttendanceNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}
 