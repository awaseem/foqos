extension ActiveProfileSyncStore {
  static func publish(session: BlockedProfileSession?) {
    publish(
      session: session?.toSnapshot(),
      profile: session.map { BlockedProfiles.getSnapshot(for: $0.blockedProfile) }
    )
  }
}
