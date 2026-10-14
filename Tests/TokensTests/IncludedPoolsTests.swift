import Foundation
import Testing
@testable import Tokens

private func parseUsageSummary(_ json: String) -> IncludedPools? {
    let data = Data(json.utf8)
    let object = try? JSONSerialization.jsonObject(with: data)
    return (object as? [String: Any]).flatMap(IncludedPools.parse(json:))
}

@Test func includedPoolsReadsPlanPercentages() {
    let pools = parseUsageSummary("""
    {
      "membershipType": "ultra",
      "isUnlimited": false,
      "individualUsage": {
        "plan": {
          "enabled": true,
          "used": 40000,
          "limit": 40000,
          "remaining": 0,
          "autoPercentUsed": 98.109,
          "apiPercentUsed": 100,
          "totalPercentUsed": 98.5128
        }
      }
    }
    """)

    #expect(pools?.cursorModelsPercent == 98.109)
    #expect(pools?.otherModelsPercent == 100)
    #expect(IncludedPools.displayPercent(98.109) == 98)
    #expect(IncludedPools.displayPercent(98.5128) == 99)
}

@Test func includedPoolsTreatsOmittedPercentageAsZero() {
    let pools = parseUsageSummary("""
    {
      "individualUsage": {
        "plan": { "enabled": true, "apiPercentUsed": 3 }
      }
    }
    """)

    #expect(pools?.cursorModelsPercent == 0)
    #expect(pools?.otherModelsPercent == 3)
}

@Test func includedPoolsKeepsUsagePastTheAllowance() {
    let pools = parseUsageSummary("""
    {
      "individualUsage": {
        "plan": { "autoPercentUsed": 142.7, "apiPercentUsed": 5, "totalPercentUsed": 80 }
      }
    }
    """)

    #expect(pools?.cursorModelsPercent == 142.7)
    #expect(IncludedPools.displayPercent(142.7) == 143)
}

@Test func includedPoolsHidesUnlimitedPlans() {
    let pools = parseUsageSummary("""
    {
      "isUnlimited": true,
      "individualUsage": {
        "plan": { "autoPercentUsed": 10, "apiPercentUsed": 10, "totalPercentUsed": 10 }
      }
    }
    """)

    #expect(pools == nil)
}

@Test func includedPoolsFallsBackToBothDisplayMessages() {
    let pools = parseUsageSummary("""
    {
      "membershipType": "team",
      "autoModelSelectedDisplayMessage": "You've used 42% of your included total usage",
      "namedModelSelectedDisplayMessage": "You've used 7.5% of your included API usage"
    }
    """)

    #expect(pools?.cursorModelsPercent == 42)
    #expect(pools?.otherModelsPercent == 7.5)
}

@Test func includedPoolsIgnoresASingleDisplayMessage() {
    let pools = parseUsageSummary("""
    {
      "autoModelSelectedDisplayMessage": "You've used 42% of your included total usage"
    }
    """)

    #expect(pools == nil)
}

@Test func cycleSpendReadsIndividualOnDemandAndIncludedBreakdown() {
    let spend = parseCycleSpend("""
    {
      "individualUsage": {
        "plan": {
          "breakdown": { "included": 2000, "bonus": 57810, "total": 59810 }
        },
        "onDemand": { "enabled": true, "used": 22886, "limit": null }
      },
      "teamUsage": {
        "onDemand": { "enabled": true, "used": 1207692, "limit": 5000000 }
      }
    }
    """)

    #expect(spend?.onDemandCents == 22886)
    #expect(spend?.includedCents == 59810)
}

@Test func cycleSpendFallsBackToTeamOnDemand() {
    let spend = parseCycleSpend("""
    {
      "teamUsage": { "onDemand": { "enabled": true, "used": 1500 } }
    }
    """)

    #expect(spend?.onDemandCents == 1500)
    #expect(spend?.includedCents == 0)
}

@Test func cycleSpendIgnoresPayloadsWithNoMoney() {
    #expect(parseCycleSpend("{}") == nil)
}

private func parseCycleSpend(_ json: String) -> CycleSpend? {
    let data = Data(json.utf8)
    let object = try? JSONSerialization.jsonObject(with: data)
    return (object as? [String: Any]).flatMap(CycleSpend.parse(json:))
}

@Test func includedPoolsIgnoresALimitMessageWithoutAPercent() {
    #expect(IncludedPools.percent(in: "You've hit your usage limit") == nil)
    #expect(parseUsageSummary("{}") == nil)
}
