.[] | select(.["ID"] != "") | {
  id: .["ID"],
  family: (.["ID"][:2]),
  class: .["Class"],
  title: .["Title"],
  definition: .["Definition"],
  additionalGuidance: (.["Additional Guidance"] | sub("( |)Related control(|s):.*";"")),
  relatedControls: (.["Additional Guidance"]  | [scan("[A-Z]{2}-[0-9x]+")]),
  parametersThatMustBeDefined: .["Parameters that must be defined"],
  suggestedPlaceholderValues: .["Suggested Placeholder Values"],
  mappings: {
      itsg33: {
         pbmm: (.["ITSG-33\nProfile 1\nPBMM\n(433)"] == "X"),
         smm: (.["ITSG-33\nProfile 3\nSMM\n(517)"] == "X"),
        },
      nist80053: {
          low: (.["NIST\n800-53R4 Low"] == "X"),
          moderate: (.["NIST\n800-53R4 Moderate"] == "X"),
          high: (.["NIST\n800-53R4 High"] == "X"),
        }
    },
    allocation: {
          department: (.["Department"] == "X"),
          itSecurityFunction: (.["IT Security Function"] == "X"),
          cioFunctionIncludingOps: (.["CIO function (including ops)"] == "X"),
          physicalSecurityGroup: (.["Physical Security Group"] == "X"),
          personnelSecurityGroup: (.["Personnel Security Group"] == "X"),
          programAndServiceDeliveryManagers: (.["Program & service delivery managers"] == "X"),
          process: (.["Process"] == "X"),
          project: (.["Project"] == "X"),
          itProjects: (.["IT Projects"] == "X"),
          facilityAndHardware: (.["Facility & Hardware"] == "X"),
          resourceAbstractionAndControlLayer: (.["Resource Abstraction and Control Layer"] == "X"),
          infrastructure: (.["Infrastructure"] == "X"),
          platform: (.["Platform"] == "X"),
          application: (.["Application"] == "X"),
      }
  } | . += {"evidencedBy": [{"timestamp": "", "url": "", "commandOutput": ""}]}
