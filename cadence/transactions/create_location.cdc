import AttendanceNFT from "../contracts/AttendanceNFT.cdc"

transaction(name: String, description: String, thumbnail: String) {
  let locationWrapper: &AttendanceNFT.LocationWrapper

  prepare(acct: AuthAccount) {
    var wrapper = acct.borrow<&AttendanceNFT.LocationWrapper>(from: AttendanceNFT.LocationStoragePath)
    if(wrapper == nil) {
      let newWrapper <-AttendanceNFT.createLocationWrapper()
      wrapper = &newWrapper as &AttendanceNFT.LocationWrapper
      acct.save<@AttendanceNFT.LocationWrapper>(<- newWrapper, to: AttendanceNFT.LocationStoragePath)
    }
    self.locationWrapper = wrapper ?? panic("Could not borrow LocationWrapper")
  }

  execute {
    AttendanceNFT.mintLocation(recipient: self.locationWrapper, name: name, description: description, thumbnail: thumbnail)
  }
}