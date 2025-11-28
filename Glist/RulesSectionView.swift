import SwiftUI

struct RulesSectionView: View {
    let rules: BookingRules
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RULES & POLICIES")
                .font(Theme.Fonts.display(size: 14))
                .foregroundColor(Theme.textPrimary)
            
            RuleRow(
                icon: "person.text.rectangle",
                title: "ID Requirement",
                detail: rules.idRequirement
            )
            
            RuleRow(
                icon: "person.badge.shield.checkmark.fill",
                title: "Age Requirement",
                detail: rules.ageRequirement
            )
            
            RuleRow(
                icon: "tshirt.fill",
                title: "Dress Code",
                detail: rules.dressCode
            )
            
            RuleRow(
                icon: "calendar.badge.exclamationmark",
                title: "Cancellation",
                detail: rules.cancellation
            )
            
            RuleRow(
                icon: "creditcard.fill",
                title: "Deposit",
                detail: rules.deposit
            )
            
            RuleRow(
                icon: "nosign",
                title: "No Show Policy",
                detail: rules.noShow
            )
        }
        .padding()
    }
}

struct RuleRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color.theme.accent)
                .font(.title3)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.bodyBold(size: 14))
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}
