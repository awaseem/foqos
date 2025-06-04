import SwiftUI

let THREADS_URL = "https://www.threads.com/@softwarecuddler"
let TWITTER_URL = "https://x.com/softwarecuddler"
let DONATE_URL = "https://buymeacoffee.com/softwarecuddler"  // You can replace this with your actual donation URL

struct SupportView: View {
    @EnvironmentObject var donationManager: TipManager

    var body: some View {
        // Thank you stamp image and header
        VStack(alignment: .center, spacing: 30) {
            Spacer()

            Image("ThankYouStamp")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)

            Text("Thank you!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text(
                "I set out to create Foqos to help people focus on life, wellness like this should always be free and simple. Reviews, shares and donations help us keep going!"
            )
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)

            Text(
                "Questions? Reach out to me."
            )
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)

            HStack(alignment: .center, spacing: 20) {
                Link(destination: URL(string: THREADS_URL)!) {
                    Image("Threads")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                }

                Link(destination: URL(string: TWITTER_URL)!) {
                    Image("Twitter")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                }
            }
            
            Spacer()
            
            ActionButton(title: "Donate", backgroundColor: .red, action: {
                donationManager.tip()
            })
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationView {
        SupportView()
            .environmentObject(TipManager())
    }
}
