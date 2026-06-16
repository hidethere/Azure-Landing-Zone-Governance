targetScope = 'subscription'

// Allowed Locations Assignemnt
resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations'

  properties: {
    displayName: 'Allowed Locations'

    policyDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/policyDefinitions',
      'e56962a6-4747-49cd-b67b-bf8b01975c4c'
    )

    parameters: {
      listOfAllowedLocations: {
        value: [
          'westeurope'
          'northeurope'
        ]
      }
    }
  }
}

// Required Tags Initiative

resource taggingInitiative 'Microsoft.Authorization/policySetDefinitions@2026-06-01' = {
  name: 'landingzone-tagging-baseline'

  properties: {
    displayName: 'Landing Zone Tagging Baseline'
    policyType: 'Custom'

    parameters: {
      tagName: {
        type: 'String'
      }
    }

    policyDefinitions: [
      {
        policyDefinitionId: subscriptionResourceId(
          'Microsoft.Authorization/policyDefinitions',
          'd52785c9-7e1c-4f86-b3b1-2b8d7f3b2f4d'
        )
        parameters: {
          tagName: {
            value: 'Owner'
          }
        }
      }
      {
        policyDefinitionId: subscriptionResourceId(
          'Microsoft.Authorization/policyDefinitions',
          'd52785c9-7e1c-4f86-b3b1-2b8d7f3b2f4d'
        )
        parameters: {
          tagName: {
            value: 'CostCenter'
          }
        }
      }
      {
        policyDefinitionId: subscriptionResourceId(
          'Microsoft.Authorization/policyDefinitions',
          'd52785c9-7e1c-4f86-b3b1-2b8d7f3b2f4d'
        )
        parameters: {
          tagName: {
            value: 'Criticality'
          }
        }
      }
      {
        policyDefinitionId: subscriptionResourceId(
          'Microsoft.Authorization/policyDefinitions',
          'd52785c9-7e1c-4f86-b3b1-2b8d7f3b2f4d'
        )
        parameters: {
          tagName: {
            value: 'Application'
          }
        }
      }
    ]
  }
}

resource taggingAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'landingzone-tagging-assignment'

  properties: {
    displayName: 'Landing Zone Tagging Enforcement'
    policyDefinitionId: taggingInitiative.id
  }
}

