resource "azurerm_api_management_api" "api_eservices_orchestrator" {
  api_management_name   = data.azurerm_api_management.apim.name
  description           = "TC.Enterprise.eServicesOrchestrator.WebService v1.8.170+Branch.main.Sha.50bdbdda99cea15fa480650961ca5901b352dd16"
  name                  = "eservices-orchestrator"
  display_name          = "eservices-orchestrator"
  path = "eservices"
  resource_group_name   = data.azurerm_resource_group.rg_deployment.name
  revision              = "1"
  subscription_required = false
  protocols             = ["https"]
  depends_on = [
    data.azurerm_api_management.apim,
  ]
}

resource "azurerm_api_management_api_operation" "api_operation_Financial_Screening_Search" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  display_name        = "Send Financial Screening request search"
  method              = "POST"
  operation_id        = "FinancialScreeningRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/FinancialScreeningRequestSearch"
  response {
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "FinancialScreening.RequestSearch.FinancialScreeningRequestSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"request\":{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"patient\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"birthDate\":\"string\",\"firstName\":\"string\",\"gender\":\"string\",\"lastName\":\"string\",\"middleName\":\"string\"},\"prescriber\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"firstName\":\"string\",\"lastName\":\"string\",\"npi\":\"string\",\"phone\":\"string\"},\"prescription\":{\"drug\":\"string\",\"ndc\":\"string\"},\"quickPathCaseId\":0},\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}

resource "azapi_resource" "access-service-token-cache-fragment" {
  type      = "Microsoft.ApiManagement/service/policyFragments@2021-12-01-preview"
  name      = "access-service-token-cache"
  parent_id = data.azurerm_api_management.apim.id

  body = jsonencode({
    properties = {
      description = "requests an access token using the salesforce-intsvc access token endpoint, and caches it based on the apiname (each api then calling the same api)"
      format      = "rawxml"
      value       = <<XML
<fragment>
	<choose>
		<when condition="@(!context.Variables.ContainsKey("tokenCacheKey"))">
			<set-variable name="tokenCacheKey" value="@(context.Api.Name.Replace(" ", "") + "Token")" />
		</when>
	</choose>
	<cache-lookup-value key="@((string)context.Variables["tokenCacheKey"])" variable-name="bearer_token" />
	<choose>
		<when condition="@(!context.Variables.ContainsKey("bearer_token"))">
			<send-request ignore-error="true" timeout="20" response-variable-name="tokenResponse" mode="new">
				<set-url>@("{{salesforce-intsvc-url}}" + "/AccessToken")</set-url>
				<set-method>POST</set-method>
				<set-header name="Content-Type" exists-action="override">
					<value>application/json</value>
				</set-header>
				<set-header name="x-functions-key" exists-action="override">
					<value>{{salesforce-intsvc-key}}</value>
				</set-header>
				<set-body>@($"{{\"audienceId\":\"{((string)context.Variables["audienceId"])}\"}}")</set-body>
			</send-request>
			<set-variable name="token_request_response" value="@((JObject)((IResponse)context.Variables["tokenResponse"]).Body.As<JObject>())" />
			<set-variable name="bearer_token" value="@((string)((JObject)context.Variables["token_request_response"])["accessToken"])" />
			<set-variable name="_expiresIn" value="@(((JObject)context.Variables["token_request_response"])["expiresIn"].Value<int>())" />
			<!-- Store result in cache -->
			<cache-store-value key="@((string)context.Variables["tokenCacheKey"])" value="@((string)context.Variables["bearer_token"])" duration="@(((int)context.Variables["_expiresIn"]) - 60)" />
		</when>
	</choose>
	<set-header name="Authorization" exists-action="override">
		<value>@("Bearer " + (string)context.Variables["bearer_token"])</value>
	</set-header>
	<!--  Don't expose APIM subscription key to the backend. -->
	<set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
</fragment>
      XML
    }
  })

  depends_on = [
    azurerm_api_management_named_value.salesforce-intsvc-key,
    azurerm_api_management_named_value.salesforce-intsvc-url,
  ]
}

resource "azurerm_api_management_api_operation_policy" "api_policy_Financial_Screening_Search" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "FinancialScreeningRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_Financial_Screening_Search,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_Financial_Screening_Result" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "FinancialScreeningResultSearch_ResultSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_Financial_Screening_Result,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_Financial_Screening_Result" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  display_name        = "Search financial screening results"
  method              = "POST"
  operation_id        = "FinancialScreeningResultSearch_ResultSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/FinancialScreeningResultSearch"
  response {
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   type_name    = "FinancialScreening.ResultSearch.FinancialScreeningResultSearchResponseModelListResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_Send_Financial_Screening" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  display_name        = "Send Financial Screening request"
  method              = "POST"
  operation_id        = "FinancialScreening_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/FinancialScreening"
  response {
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "FinancialScreening.FinancialScreeningResponseModelResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":{\"customerID\":\"string\",\"eligibilityStatus\":true,\"fpl\":\"string\",\"householdEstimatedIncome\":\"string\",\"householdEstimatedSize\":\"string\",\"requestId\":0,\"resultId\":0,\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true},\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "BaseResponseModelResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":{\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true},\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_Send_Financial_Screening" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "FinancialScreening_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_Send_Financial_Screening,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_medicalBi" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_medicalBi_RequestSearch.id
#   display_name     = "MedicalBi"
#   name             = "MedicalBi"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_medicalBi_RequestSearch,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_medicalBi_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "MedicalBiRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_medicalBi_RequestSearch,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_medicalBi_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send medical bi result"
  display_name        = "Search medical bi request"
  method              = "POST"
  operation_id        = "MedicalBiRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/MedicalBiRequestSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "MedicalBi.RequestSearch.MedicalBiRequestSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"request\":{\"chainPbm\":true,\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"diagnosis\":{\"cptCodes\":[{\"code\":\"string\",\"unit\":\"string\"}],\"jCodes\":[{\"code\":\"string\",\"unit\":\"string\"}],\"primaryIcdCode\":\"string\",\"primaryIcdDescription\":\"string\",\"secondaryIcdCode\":\"string\",\"secondaryIcdDescription\":\"string\",\"treatmentDate\":\"string\"},\"facility\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"name\":\"string\",\"npi\":\"string\",\"phone\":\"string\"},\"patient\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"birthDate\":\"string\",\"firstName\":\"string\",\"gender\":\"string\",\"lastName\":\"string\",\"middleName\":\"string\"},\"payor\":{\"groupId\":\"string\",\"groupName\":\"string\",\"id\":\"string\",\"memberId\":\"string\",\"name\":\"string\",\"otherInsuranceStatus\":\"string\"},\"practice\":{\"additionalId\":\"string\",\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"name\":\"string\",\"npi\":\"string\",\"phone\":\"string\",\"taxId\":\"string\",\"type\":\"string\"},\"preferredSpecialtyPharmacy\":true,\"prescriber\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"firstName\":\"string\",\"lastName\":\"string\",\"npi\":\"string\",\"taxId\":\"string\"},\"prescription\":{\"daySupply\":\"string\",\"drug\":\"string\",\"ndc\":\"string\",\"quantity\":\"string\",\"refill\":\"string\",\"sig\":\"string\"},\"providerProgramId\":\"string\",\"quickPathCaseId\":0,\"specialtyPharmacyName\":\"string\"},\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no content"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "ResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_medicalBi_ResultSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send medical bi result"
  display_name        = "Search medical bi result"
  method              = "POST"
  operation_id        = "MedicalBiResultSearch_ResultSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/MedicalBiResultSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "MedicalBi.ResultSearch.MedicalBiResultSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"quickPathCaseId\":0,\"result\":{\"additionalNotes\":\"string\",\"annualCap\":\"string\",\"annualCapExist\":true,\"annualCapMetAmount\":0,\"appeal\":{\"available\":\"string\",\"contactFax\":\"string\",\"contactOrg\":\"string\",\"contactPhone\":\"string\",\"numberAvailable\":\"string\",\"requiredDocuments\":\"string\",\"submissionDeadline\":\"string\",\"turnaroundTime\":\"string\"},\"benefitNetworkStatus\":\"string\",\"benefitsNotes\":\"string\",\"buyAndBillAvailable\":\"string\",\"claimAddress\":\"string\",\"coInsurance\":\"string\",\"cobraPlan\":{\"gracePeriod\":\"string\",\"isSet\":true,\"paidThroughDate\":\"string\"},\"coordinationOfBenefits\":\"string\",\"copay\":{\"appliesToOop\":\"string\",\"copay\":\"string\",\"notes\":\"string\",\"waivedAfterOpp\":true},\"cptCodes\":[{\"coInsurance\":\"string\",\"code\":\"string\",\"copay\":\"string\",\"deductibleApplies\":true,\"notes\":\"string\",\"priorAuthorizationRequired\":true,\"unit\":\"string\"}],\"createdTimestamp\":\"string\",\"deductibleApplies\":true,\"deductibleIncludedInOop\":true,\"denial\":{\"date\":\"string\",\"number\":\"string\",\"reason\":\"string\"},\"facility\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"name\":\"string\",\"npi\":\"string\",\"phone\":\"string\"},\"family\":{\"deductibleMet\":0,\"deductibleTotal\":0,\"oopMax\":0,\"oopMet\":0},\"followsMedicareGuidelines\":\"string\",\"healthExchangePlan\":{\"gracePeriod\":\"string\",\"isSet\":true,\"paidThroughDate\":\"string\"},\"individual\":{\"deductibleMet\":0,\"deductibleTotal\":0,\"oopMax\":0,\"oopMet\":0},\"jCodes\":[{\"coInsurance\":\"string\",\"code\":\"string\",\"copay\":\"string\",\"deductibleApplies\":true,\"notes\":\"string\",\"priorAuthorizationRequired\":true,\"unit\":\"string\"}],\"lifetime\":{\"maxAmount\":0,\"maxMet\":0,\"maximumExists\":\"string\"},\"medical\":{\"groupName\":\"string\",\"groupPhone\":\"string\",\"policyAvailableOnWebsite\":\"string\",\"policyNumber\":\"string\"},\"multipleCopay\":true,\"obtainPreDetermination\":{\"fax\":\"string\",\"org\":\"string\",\"phone\":\"string\",\"website\":\"string\"},\"obtainPriorAuthorization\":{\"fax\":\"string\",\"org\":\"string\",\"phone\":\"string\",\"requirements\":\"string\",\"website\":\"string\"},\"patient\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"birthDate\":\"string\",\"firstName\":\"string\",\"gender\":\"string\",\"lastName\":\"string\",\"middleName\":\"string\",\"receivesSubsidies\":\"string\"},\"payor\":{\"agentName\":\"string\",\"groupId\":\"string\",\"groupName\":\"string\",\"hasSecondaryInsurance\":true,\"hasStandardPlanLetter\":true,\"id\":\"string\",\"inNetworkConsideration\":\"string\",\"isAccumulatorPlan\":true,\"isMaximizerPlan\":true,\"memberId\":\"string\",\"name\":\"string\",\"newPlanAvailable\":true,\"newPlanEffectiveDate\":\"string\",\"newPlanSubscriberId\":\"string\",\"phone\":\"string\",\"planEffectiveDate\":\"string\",\"planFundType\":\"string\",\"planName\":\"string\",\"planPriority\":0,\"planRenewalMonth\":\"string\",\"planRenewalType\":\"string\",\"planTerminationDate\":\"string\",\"planType\":\"string\",\"policyType\":\"string\",\"referenceId\":\"string\",\"secondaryInsuranceName\":\"string\",\"standardPlanLetter\":\"string\",\"willCoverIfPrimaryDenies\":\"string\",\"willCoverPartBDeductible\":\"string\"},\"pbm\":{\"exists\":true,\"name\":\"string\",\"phone\":\"string\"},\"pcp\":{\"name\":\"string\",\"phone\":\"string\"},\"peerToPeer\":{\"available\":\"string\",\"phone\":\"string\",\"submissionDeadline\":\"string\"},\"practice\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"name\":\"string\",\"npi\":\"string\",\"phone\":\"string\",\"taxId\":\"string\",\"type\":\"string\"},\"preDetermination\":{\"approvedQuantity\":\"string\",\"approvedQuantityUsed\":\"string\",\"available\":true,\"endDate\":\"string\",\"number\":\"string\",\"onFile\":true,\"renewalProcessExists\":true,\"required\":true,\"requirement\":\"string\",\"startDate\":\"string\",\"turnaroundTime\":\"string\"},\"preferredSpecialty\":{\"pharmacy\":\"string\",\"phone\":\"string\"},\"prescriber\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"firstName\":\"string\",\"inNetwork\":\"string\",\"lastName\":\"string\",\"npi\":\"string\",\"taxId\":\"string\"},\"prescription\":{\"daySupply\":\"string\",\"drug\":\"string\",\"ndc\":\"string\",\"quantity\":\"string\",\"refill\":\"string\",\"sig\":\"string\"},\"priorAuthorization\":{\"approvalNumber\":\"string\",\"approvedQuantity\":\"string\",\"approvedQuantityUsed\":\"string\",\"endDate\":\"string\",\"onFile\":true,\"renewalProcessExists\":true,\"required\":true,\"requiredCodes\":\"string\",\"responsibleOrg\":\"string\",\"startDate\":\"string\",\"status\":\"string\",\"turnaroundTime\":\"string\"},\"reasonForNonCoverage\":\"string\",\"referral\":{\"effectiveDate\":\"string\",\"number\":\"string\",\"onFile\":true,\"recertDate\":\"string\",\"required\":true,\"requirements\":\"string\",\"visitsApproved\":\"string\",\"visitsUsed\":\"string\"},\"reviewRequired\":true,\"specialtyPharmacy\":{\"available\":\"string\",\"coInsurance\":\"string\",\"copay\":\"string\",\"exclusions\":\"string\",\"fax\":\"string\",\"name\":\"string\",\"phone\":\"string\"},\"spendDown\":{\"exist\":true,\"met\":0,\"total\":0},\"stepTherapy\":{\"required\":true,\"treatment\":\"string\"},\"taskCompletedDate\":\"string\",\"taskStatus\":\"string\",\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true,\"updatedTimestamp\":\"string\"}}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no results"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_medicalBi_ResultSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "MedicalBiResultSearch_ResultSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_medicalBi_ResultSearch,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_medicalBi_ResultSearch" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_medicalBi_ResultSearch.id
#   display_name     = "MedicalBi"
#   name             = "MedicalBi"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_medicalBi_ResultSearch,
#   ]
# }
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_medicalBi_Request" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_medicalBi_Request.id
#   display_name     = "MedicalBi"
#   name             = "MedicalBi"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_medicalBi_Request,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_medicalBi_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "MedicalBi_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_medicalBi_Request,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_medicalBi_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send medical bi request"
  display_name        = "Send medical bi request"
  method              = "POST"
  operation_id        = "MedicalBi_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/MedicalBi"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "MedicalBi.MedicalBiResponseModelResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":{\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true},\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_medicalEligibility_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send Medical Eligibility request search"
  display_name        = "Search Medical Eligibility request"
  method              = "POST"
  operation_id        = "MedicalEligibilityRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/MedicalEligibilityRequestSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "MedicalEligibility.RequestSearch.MedicalEligibilityRequestSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"request\":{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"maskedCaseId\":\"string\",\"patient\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"birthDate\":\"string\",\"firstName\":\"string\",\"gender\":\"string\",\"lastName\":\"string\",\"middleName\":\"string\"},\"payor\":{\"groupId\":\"string\",\"id\":\"string\",\"memberId\":\"string\",\"name\":\"string\"},\"practice\":{\"additionalId\":\"string\",\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"name\":\"string\",\"npi\":\"string\",\"phone\":\"string\",\"taxId\":\"string\",\"type\":\"string\"},\"prescriber\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"firstName\":\"string\",\"lastName\":\"string\",\"npi\":\"string\",\"taxId\":\"string\"},\"programId\":\"string\",\"quickPathCaseId\":0,\"treatmentDate\":\"string\"},\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no content"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_medicalEligibility_RequestSearch" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_medicalEligibility_RequestSearch.id
#   display_name     = "MedicalEligibility"
#   name             = "MedicalEligibility"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_medicalEligibility_RequestSearch,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_medicalEligibility_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "MedicalEligibilityRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_medicalEligibility_RequestSearch,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_medicalEligibility_ResponseSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send Medical Eligibility result search"
  display_name        = "Search Medical Eligibility result"
  method              = "POST"
  operation_id        = "MedicalEligibilityResultSearch_ResponseSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/MedicalEligibilityResultSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "MedicalEligibility.ResultSearch.MedicalEligibilityResultSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"quickPathCaseId\":0,\"result\":{\"annualBenefitCap\":\"string\",\"annualBenefitCapMetAmount\":\"string\",\"coPayAppliesToOop\":\"string\",\"copayWaivedAfterOPP\":\"string\",\"familyCoInsurance\":\"string\",\"familyDeductible\":\"string\",\"familyDeductibleMet\":\"string\",\"familyDeductibleOutNetwork\":\"string\",\"familyDeductibleRemaining\":\"string\",\"familyOop\":\"string\",\"familyOopMet\":\"string\",\"familyOopOutNetwork\":\"string\",\"familyOopRemaining\":\"string\",\"groupId\":\"string\",\"groupName\":\"string\",\"individualCoInsurance\":\"string\",\"individualDeductible\":\"string\",\"individualDeductibleMet\":\"string\",\"individualDeductibleOutNetwork\":\"string\",\"individualDeductibleRemaining\":\"string\",\"individualDeductibleRemainingOutNetwork\":\"string\",\"individualOop\":\"string\",\"individualOopMet\":\"string\",\"individualOopOutNetwork\":\"string\",\"individualOopRemaining\":\"string\",\"individualOopRemainingOutNetwork\":\"string\",\"insurancePolicyNumber\":\"string\",\"isAccumulatorPlan\":\"string\",\"isMaximizerPlan\":\"string\",\"lifetimeMaximumAmount\":\"string\",\"lifetimeMaximumExists\":\"string\",\"lifetimeMaximumMet\":\"string\",\"memberId\":\"string\",\"patientAddressLine1\":\"string\",\"patientAddressLine2\":\"string\",\"patientChangeFlag\":true,\"patientCity\":\"string\",\"patientDateOfBirth\":\"string\",\"patientFirstName\":\"string\",\"patientGender\":\"string\",\"patientLastName\":\"string\",\"patientMiddleName\":\"string\",\"patientRelation\":\"string\",\"patientState\":\"string\",\"patientZipCode\":\"string\",\"payerId\":\"string\",\"payerName\":\"string\",\"payerPhoneNumber\":\"string\",\"payerReferenceId\":\"string\",\"pbmExists\":true,\"pbmName\":\"string\",\"pbmPhoneNumber\":\"string\",\"planEffectiveDate\":\"string\",\"planName\":\"string\",\"planPriority\":\"string\",\"planTerminationDate\":\"string\",\"planType\":\"string\",\"preferredSpecialtyPharmacy\":\"string\",\"preferredSpecialtyPhoneNo\":\"string\",\"prescriberAddressLine1\":\"string\",\"prescriberAddressLine2\":\"string\",\"prescriberCity\":\"string\",\"prescriberFirstName\":\"string\",\"prescriberInNetwork\":\"string\",\"prescriberLastName\":\"string\",\"prescriberNpi\":\"string\",\"prescriberState\":\"string\",\"prescriberTaxId\":\"string\",\"prescriberZipCode\":\"string\",\"priorIdentifierNumber\":\"string\",\"programId\":\"string\",\"secondaryInsuranceExists\":true,\"secondaryInsuranceName\":\"string\",\"specialtyPharmacyAvailability\":\"string\",\"specialtyPharmacyCoInsurance\":\"string\",\"specialtyPharmacyCopay\":\"string\",\"specialtyPharmacyName\":\"string\",\"specialtyPharmacyPhoneNumber\":\"string\",\"spendDownExists\":true,\"taskStatus\":\"string\",\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no content"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_medicalEligibility_ResponseSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "MedicalEligibilityResultSearch_ResponseSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_medicalEligibility_ResponseSearch,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_medicalEligibility_ResponseSearch" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_medicalEligibility_ResponseSearch.id
#   display_name     = "MedicalEligibility"
#   name             = "MedicalEligibility"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_medicalEligibility_ResponseSearch,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_medicalEligibility_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "MedicalEligibility_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_medicalEligibility_Request,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_medicalEligibility_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send medical eligibility request"
  display_name        = "Send medical eligibility request"
  method              = "POST"
  operation_id        = "MedicalEligibility_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/MedicalEligibility"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "MedicalEligibility.MedicalEligibilityResponseModelResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":{\"annualBenefitCap\":\"string\",\"annualBenefitCapMetAmount\":\"string\",\"coPayAppliesToOop\":\"string\",\"copayWaivedAfterOPP\":\"string\",\"familyCoInsurance\":\"string\",\"familyDeductible\":\"string\",\"familyDeductibleMet\":\"string\",\"familyDeductibleOutNetwork\":\"string\",\"familyDeductibleRemaining\":\"string\",\"familyOop\":\"string\",\"familyOopMet\":\"string\",\"familyOopOutNetwork\":\"string\",\"familyOopRemaining\":\"string\",\"groupId\":\"string\",\"groupName\":\"string\",\"individualCoInsurance\":\"string\",\"individualDeductible\":\"string\",\"individualDeductibleMet\":\"string\",\"individualDeductibleOutNetwork\":\"string\",\"individualDeductibleRemaining\":\"string\",\"individualDeductibleRemainingOutNetwork\":\"string\",\"individualOop\":\"string\",\"individualOopMet\":\"string\",\"individualOopOutNetwork\":\"string\",\"individualOopRemaining\":\"string\",\"individualOopRemainingOutNetwork\":\"string\",\"insurancePolicyNumber\":\"string\",\"isAccumulatorPlan\":\"string\",\"isMaximizerPlan\":\"string\",\"lifetimeMaximumAmount\":\"string\",\"lifetimeMaximumExists\":\"string\",\"lifetimeMaximumMet\":\"string\",\"memberId\":\"string\",\"patientAddressLine1\":\"string\",\"patientAddressLine2\":\"string\",\"patientChangeFlag\":true,\"patientCity\":\"string\",\"patientDateOfBirth\":\"string\",\"patientFirstName\":\"string\",\"patientGender\":\"string\",\"patientLastName\":\"string\",\"patientMiddleName\":\"string\",\"patientRelation\":\"string\",\"patientState\":\"string\",\"patientZipCode\":\"string\",\"payerId\":\"string\",\"payerName\":\"string\",\"payerPhoneNumber\":\"string\",\"payerReferenceId\":\"string\",\"pbmExists\":true,\"pbmName\":\"string\",\"pbmPhoneNumber\":\"string\",\"planEffectiveDate\":\"string\",\"planName\":\"string\",\"planPriority\":\"string\",\"planTerminationDate\":\"string\",\"planType\":\"string\",\"preferredSpecialtyPharmacy\":\"string\",\"preferredSpecialtyPhoneNo\":\"string\",\"prescriberAddressLine1\":\"string\",\"prescriberAddressLine2\":\"string\",\"prescriberCity\":\"string\",\"prescriberFirstName\":\"string\",\"prescriberInNetwork\":\"string\",\"prescriberLastName\":\"string\",\"prescriberNpi\":\"string\",\"prescriberState\":\"string\",\"prescriberTaxId\":\"string\",\"prescriberZipCode\":\"string\",\"priorIdentifierNumber\":\"string\",\"programId\":\"string\",\"secondaryInsuranceExists\":true,\"secondaryInsuranceName\":\"string\",\"specialtyPharmacyAvailability\":\"string\",\"specialtyPharmacyCoInsurance\":\"string\",\"specialtyPharmacyCopay\":\"string\",\"specialtyPharmacyName\":\"string\",\"specialtyPharmacyPhoneNumber\":\"string\",\"spendDownExists\":true,\"taskStatus\":\"string\",\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true},\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Bad Request"
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "BaseResponseModelResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":{\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true},\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_medicalEligibility_Request" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_medicalEligibility_Request.id
#   display_name     = "MedicalEligibility"
#   name             = "MedicalEligibility"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_medicalEligibility_Request,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_PharmacyBiRequestSearch_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "PharmacyBiRequestSearch_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_PharmacyBiRequestSearch_Request,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_PharmacyBiRequestSearch_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send pharmacy bi request search"
  display_name        = "Search pharmacy bi request"
  method              = "POST"
  operation_id        = "PharmacyBiRequestSearch_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/PharmacyBiRequestSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "PharmacyBi.RequestSearch.PharmacyBiRequestSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"request\":{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"diagnosis\":{\"jCode\":\"string\",\"jCodeDescription\":\"string\",\"primaryIcdCode\":\"string\",\"primaryIcdDescription\":\"string\",\"secondaryIcdCode\":\"string\",\"secondaryIcdDescription\":\"string\",\"treatmentDate\":\"string\"},\"patient\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"birthDate\":\"string\",\"firstName\":\"string\",\"gender\":\"string\",\"lastName\":\"string\",\"middleName\":\"string\"},\"payor\":{\"bin\":\"string\",\"cardHolderId\":\"string\",\"groupId\":\"string\",\"groupName\":\"string\",\"id\":\"string\",\"name\":\"string\",\"otherInsuranceStatus\":\"string\",\"pcn\":\"string\",\"phone\":\"string\",\"planName\":\"string\"},\"pharmacyNPI\":\"string\",\"practice\":{\"additionalId\":\"string\",\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"name\":\"string\",\"npi\":\"string\",\"phone\":\"string\",\"taxId\":\"string\",\"type\":\"string\"},\"prescriber\":{\"address\":{\"address1\":\"string\",\"address2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"firstName\":\"string\",\"inNetwork\":\"string\",\"lastName\":\"string\",\"npi\":\"string\",\"phone\":\"string\",\"taxId\":\"string\"},\"prescription\":{\"daySupply\":\"string\",\"drug\":\"string\",\"ndc\":\"string\",\"quantity\":\"string\",\"refill\":\"string\",\"sig\":\"string\"},\"providerProgramId\":\"string\",\"quickPathCaseId\":0,\"specialtyPharmacy\":{\"name\":\"string\",\"npi\":\"string\",\"preferred\":true}},\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no content"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_PharmacyBiRequestSearch_Request" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_PharmacyBiRequestSearch_Request.id
#   display_name     = "PharmacyBi"
#   name             = "PharmacyBi"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_PharmacyBiRequestSearch_Request,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_PharmacyBiResultSearch_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "PharmacyBiResultSearch_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_PharmacyBiResultSearch_Request,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_PharmacyBiResultSearch_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send pharmacy bi result search"
  display_name        = "Search pharmacy bi result"
  method              = "POST"
  operation_id        = "PharmacyBiResultSearch_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/PharmacyBiResultSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "PharmacyBi.ResultSearch.PharmacyBiResultSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"quickPathCaseId\":0,\"result\":{\"customerId\":\"string\",\"plans\":[{\"accumulatedDeductibleAmount\":\"string\",\"additionalNotes\":\"string\",\"annualBenefitCap\":\"string\",\"annualBenefitCapMetAmount\":\"string\",\"annualCapExists\":true,\"appealAvailable\":\"string\",\"appealContactFax\":\"string\",\"appealContactOrg\":\"string\",\"appealContactPhone\":\"string\",\"appealsNotificationMethod\":\"string\",\"appealsRequiredDocuments\":\"string\",\"appealsSubmissionDeadline\":\"string\",\"appealsTurnaroundTime\":\"string\",\"bin\":\"string\",\"cardHolderId\":\"string\",\"coPayAppliesToOop\":true,\"coordinationOfBenefits\":\"string\",\"customerId\":\"string\",\"daysSupplyPriced\":0,\"deductibleAppliedAmount\":\"string\",\"deductibleIncludedInOop\":true,\"deductibleRemainingAmount\":\"string\",\"denialDate\":\"string\",\"denialNotes\":\"string\",\"denialNumber\":\"string\",\"denialReason\":\"string\",\"drugCoverageStatus\":\"string\",\"estimatedPatientPayAmount\":\"string\",\"familyDeductibleExists\":true,\"familyDeductibleMet\":\"string\",\"familyDeductibleTotal\":\"string\",\"familyOopMaximum\":\"string\",\"familyOopMaximumExists\":true,\"familyOopMet\":\"string\",\"familyUnitNumber\":\"string\",\"individualDeductibleExists\":true,\"individualDeductibleMet\":\"string\",\"individualDeductibleTotal\":\"string\",\"individualOopMaximum\":\"string\",\"individualOopMaximumExists\":true,\"individualOopMet\":\"string\",\"initialCoverageLimitMetAmount\":\"string\",\"initialCoverageLimitTotal\":\"string\",\"insurancePriority\":\"string\",\"insuranceType\":\"string\",\"isAccumulatorPlan\":true,\"isMaximizerPlan\":true,\"isOnLowIncomeSubsidy\":true,\"lifetimeMaximumAmount\":\"string\",\"lifetimeMaximumExists\":true,\"lifetimeMaximumMet\":\"string\",\"lowIncomeSubsidyLevel\":\"string\",\"mailOrderPharmacyName\":\"string\",\"mailOrderPharmacyPhone\":\"string\",\"medicarePartDCatastrophicCoInsuranceValue\":\"string\",\"medicarePartDCurrentStage\":\"string\",\"medicarePartDGapCoInsuranceValue\":\"string\",\"newPlanAvailable\":true,\"newPlanEffectiveDate\":\"string\",\"newPlanSubscriberId\":\"string\",\"obtainPriorAuthorizationFax\":\"string\",\"obtainPriorAuthorizationOrg\":\"string\",\"obtainPriorAuthorizationPhone\":\"string\",\"obtainPriorAuthorizationRequirements\":\"string\",\"obtainPriorAuthorizationWebsite\":\"string\",\"obtainTierExceptionPhone\":\"string\",\"otherInsuranceExists\":true,\"payerAgentName\":\"string\",\"payerId\":\"string\",\"payerPhoneNumber\":\"string\",\"payerReferenceId\":\"string\",\"pbmName\":\"string\",\"pbmPayorName\":\"string\",\"pbmPhoneNumber\":\"string\",\"pbmResponseMessage\":\"string\",\"pbmSpecialtyPharmacyRequirement\":\"string\",\"pcn\":\"string\",\"peerToPeerAvailable\":true,\"peerToPeerPhone\":\"string\",\"peerToPeerSubmissionDeadline\":\"string\",\"pharmacyNcpdpId\":\"string\",\"pharmacyNpi\":\"string\",\"planEffectiveDate\":\"string\",\"planGroupNo\":\"string\",\"planName\":\"string\",\"planPriority\":\"string\",\"planRenewalMonth\":\"string\",\"planRenewalType\":\"string\",\"planTerminationDate\":\"string\",\"planType\":\"string\",\"policyNumber\":\"string\",\"policyType\":\"string\",\"preferredDrugValue\":true,\"priorAuthAppealsContactFax\":\"string\",\"priorAuthDenialReason\":\"string\",\"priorAuthInitiationDate\":\"string\",\"priorAuthNotificationMethod\":\"string\",\"priorAuthorizationApprovalNumber\":\"string\",\"priorAuthorizationEndDate\":\"string\",\"priorAuthorizationOnFile\":true,\"priorAuthorizationRequired\":true,\"priorAuthorizationStartDate\":\"string\",\"priorAuthorizationStatus\":\"string\",\"priorAuthorizationSubmissionDate\":\"string\",\"priorAuthorizationTurnaroundTime\":\"string\",\"productCoverage\":{\"code\":\"string\",\"covered\":true,\"mailOrderCoInsurance\":\"string\",\"mailOrderCovered\":true,\"mailOrderPharmacyCoPay\":\"string\",\"retailPharmacyCoInsurance\":\"string\",\"retailPharmacyCoPay\":\"string\",\"retailPharmacyCovered\":true,\"specialtyPharmacyCoInsurance\":\"string\",\"specialtyPharmacyCopay\":\"string\"},\"productQuantityLimit\":\"string\",\"productTier\":\"string\",\"programId\":\"string\",\"quantityPriced\":\"string\",\"quantityUnitDescription\":\"string\",\"quantityUnitOfMeasure\":\"string\",\"rejectionCode\":\"string\",\"resubmissionNotificationMethod\":\"string\",\"resubmissionTurnaroundTime\":\"string\",\"reviewRequired\":true,\"rxGroupId\":\"string\",\"rxGroupNo\":\"string\",\"specialtyPharmacy2Fax\":\"string\",\"specialtyPharmacy2Name\":\"string\",\"specialtyPharmacy2PhoneNumber\":\"string\",\"specialtyPharmacy3Fax\":\"string\",\"specialtyPharmacy3Name\":\"string\",\"specialtyPharmacy3PhoneNumber\":\"string\",\"specialtyPharmacyFax\":\"string\",\"specialtyPharmacyName\":\"string\",\"specialtyPharmacyPhoneNumber\":\"string\",\"stepTherapyRequired\":true,\"stepTherapyTreatment\":\"string\",\"therapyAvailabilityDate\":\"string\",\"tierExceptionProcess\":true,\"totalTier\":\"string\",\"willCoverIfPrimaryDenies\":\"string\"}],\"requestId\":0,\"resultId\":0,\"status\":true,\"taskCompletedDate\":\"string\",\"taskCreatedDate\":\"string\",\"taskStatus\":\"string\",\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no content"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_PharmacyBiResultSearch_Request" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_PharmacyBiResultSearch_Request.id
#   display_name     = "PharmacyBi"
#   name             = "PharmacyBi"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_PharmacyBiResultSearch_Request,
#   ]
# }
resource "azurerm_api_management_api_operation" "api_operation_PharmacyBi_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Send pharmacy bi request"
  display_name        = "Send pharmacy bi request"
  method              = "POST"
  operation_id        = "PharmacyBi_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/PharmacyBi"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "PharmacyBi.PharmacyBiResponseModelResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":{\"customerId\":\"string\",\"plans\":[{\"accumulatedDeductibleAmount\":\"string\",\"additionalNotes\":\"string\",\"annualBenefitCap\":\"string\",\"annualBenefitCapMetAmount\":\"string\",\"annualCapExists\":true,\"appealAvailable\":\"string\",\"appealContactFax\":\"string\",\"appealContactOrg\":\"string\",\"appealContactPhone\":\"string\",\"appealsNotificationMethod\":\"string\",\"appealsRequiredDocuments\":\"string\",\"appealsSubmissionDeadline\":\"string\",\"appealsTurnaroundTime\":\"string\",\"bin\":\"string\",\"cardHolderId\":\"string\",\"coPayAppliesToOop\":true,\"coordinationOfBenefits\":\"string\",\"customerId\":\"string\",\"daysSupplyPriced\":0,\"deductibleAppliedAmount\":\"string\",\"deductibleIncludedInOop\":true,\"deductibleRemainingAmount\":\"string\",\"denialDate\":\"string\",\"denialNotes\":\"string\",\"denialNumber\":\"string\",\"denialReason\":\"string\",\"drugCoverageStatus\":\"string\",\"estimatedPatientPayAmount\":\"string\",\"familyDeductibleExists\":true,\"familyDeductibleMet\":\"string\",\"familyDeductibleTotal\":\"string\",\"familyOopMaximum\":\"string\",\"familyOopMaximumExists\":true,\"familyOopMet\":\"string\",\"familyUnitNumber\":\"string\",\"individualDeductibleExists\":true,\"individualDeductibleMet\":\"string\",\"individualDeductibleTotal\":\"string\",\"individualOopMaximum\":\"string\",\"individualOopMaximumExists\":true,\"individualOopMet\":\"string\",\"initialCoverageLimitMetAmount\":\"string\",\"initialCoverageLimitTotal\":\"string\",\"insurancePriority\":\"string\",\"insuranceType\":\"string\",\"isAccumulatorPlan\":true,\"isMaximizerPlan\":true,\"isOnLowIncomeSubsidy\":true,\"lifetimeMaximumAmount\":\"string\",\"lifetimeMaximumExists\":true,\"lifetimeMaximumMet\":\"string\",\"lowIncomeSubsidyLevel\":\"string\",\"mailOrderPharmacyName\":\"string\",\"mailOrderPharmacyPhone\":\"string\",\"medicarePartDCatastrophicCoInsuranceValue\":\"string\",\"medicarePartDCurrentStage\":\"string\",\"medicarePartDGapCoInsuranceValue\":\"string\",\"newPlanAvailable\":true,\"newPlanEffectiveDate\":\"string\",\"newPlanSubscriberId\":\"string\",\"obtainPriorAuthorizationFax\":\"string\",\"obtainPriorAuthorizationOrg\":\"string\",\"obtainPriorAuthorizationPhone\":\"string\",\"obtainPriorAuthorizationRequirements\":\"string\",\"obtainPriorAuthorizationWebsite\":\"string\",\"obtainTierExceptionPhone\":\"string\",\"otherInsuranceExists\":true,\"payerAgentName\":\"string\",\"payerId\":\"string\",\"payerPhoneNumber\":\"string\",\"payerReferenceId\":\"string\",\"pbmName\":\"string\",\"pbmPayorName\":\"string\",\"pbmPhoneNumber\":\"string\",\"pbmResponseMessage\":\"string\",\"pbmSpecialtyPharmacyRequirement\":\"string\",\"pcn\":\"string\",\"peerToPeerAvailable\":true,\"peerToPeerPhone\":\"string\",\"peerToPeerSubmissionDeadline\":\"string\",\"pharmacyNcpdpId\":\"string\",\"pharmacyNpi\":\"string\",\"planEffectiveDate\":\"string\",\"planGroupNo\":\"string\",\"planName\":\"string\",\"planPriority\":\"string\",\"planRenewalMonth\":\"string\",\"planRenewalType\":\"string\",\"planTerminationDate\":\"string\",\"planType\":\"string\",\"policyNumber\":\"string\",\"policyType\":\"string\",\"preferredDrugValue\":true,\"priorAuthAppealsContactFax\":\"string\",\"priorAuthDenialReason\":\"string\",\"priorAuthInitiationDate\":\"string\",\"priorAuthNotificationMethod\":\"string\",\"priorAuthorizationApprovalNumber\":\"string\",\"priorAuthorizationEndDate\":\"string\",\"priorAuthorizationOnFile\":true,\"priorAuthorizationRequired\":true,\"priorAuthorizationStartDate\":\"string\",\"priorAuthorizationStatus\":\"string\",\"priorAuthorizationSubmissionDate\":\"string\",\"priorAuthorizationTurnaroundTime\":\"string\",\"productCoverage\":{\"code\":\"string\",\"covered\":true,\"mailOrderCoInsurance\":\"string\",\"mailOrderCovered\":true,\"mailOrderPharmacyCoPay\":\"string\",\"retailPharmacyCoInsurance\":\"string\",\"retailPharmacyCoPay\":\"string\",\"retailPharmacyCovered\":true,\"specialtyPharmacyCoInsurance\":\"string\",\"specialtyPharmacyCopay\":\"string\"},\"productQuantityLimit\":\"string\",\"productTier\":\"string\",\"programId\":\"string\",\"quantityPriced\":\"string\",\"quantityUnitDescription\":\"string\",\"quantityUnitOfMeasure\":\"string\",\"rejectionCode\":\"string\",\"resubmissionNotificationMethod\":\"string\",\"resubmissionTurnaroundTime\":\"string\",\"reviewRequired\":true,\"rxGroupId\":\"string\",\"rxGroupNo\":\"string\",\"specialtyPharmacy2Fax\":\"string\",\"specialtyPharmacy2Name\":\"string\",\"specialtyPharmacy2PhoneNumber\":\"string\",\"specialtyPharmacy3Fax\":\"string\",\"specialtyPharmacy3Name\":\"string\",\"specialtyPharmacy3PhoneNumber\":\"string\",\"specialtyPharmacyFax\":\"string\",\"specialtyPharmacyName\":\"string\",\"specialtyPharmacyPhoneNumber\":\"string\",\"stepTherapyRequired\":true,\"stepTherapyTreatment\":\"string\",\"therapyAvailabilityDate\":\"string\",\"tierExceptionProcess\":true,\"totalTier\":\"string\",\"willCoverIfPrimaryDenies\":\"string\"}],\"requestId\":0,\"resultId\":0,\"status\":true,\"taskCompletedDate\":\"string\",\"taskCreatedDate\":\"string\",\"taskStatus\":\"string\",\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true},\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_PharmacyBi_Request" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "PharmacyBi_Request"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_PharmacyBi_Request,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_PharmacyBi_Request" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_PharmacyBi_Request.id
#   display_name     = "PharmacyBi"
#   name             = "PharmacyBi"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_PharmacyBi_Request,
#   ]
# }
resource "azurerm_api_management_api_operation" "api_operation_PharmacyCardFinderRequestSearch_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Search pharmacy card finder requests"
  display_name        = "Search pharmacy card finder requests"
  method              = "POST"
  operation_id        = "PharmacyCardFinderRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/PharmacyCardFinderRequestSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "PharmacyCardFinder.RequestSearch.PharmacyCardFinderRequestSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"request\":{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"daysSupply\":\"string\",\"ndc\":\"string\",\"patient\":{\"dateOfBirth\":\"string\",\"firstName\":\"string\",\"gender\":\"string\",\"lastName\":\"string\",\"phone\":\"string\",\"zipCode\":\"string\"},\"pharmacyNcpDpId\":\"string\",\"pharmacyNpi\":\"string\",\"prescriber\":{\"address\":{\"addressLine1\":\"string\",\"addressLine2\":\"string\",\"city\":\"string\",\"state\":\"string\",\"zipCode\":\"string\"},\"fax\":\"string\",\"firstName\":\"string\",\"lastName\":\"string\",\"npi\":\"string\",\"phone\":\"string\"},\"quantity\":\"string\",\"quickPathCaseId\":0},\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no content"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_PharmacyCardFinderRequestSearch_RequestSearch" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_PharmacyCardFinderRequestSearch_RequestSearch.id
#   display_name     = "PharmacyCardFinder"
#   name             = "PharmacyCardFinder"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_PharmacyCardFinderRequestSearch_RequestSearch,
#   ]
# }
resource "azurerm_api_management_api_operation" "api_operation_PharmacyCardFinderResultSearch_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Search pharmacy card finder results"
  display_name        = "Search pharmacy card finder results"
  method              = "POST"
  operation_id        = "PharmacyCardFinderResultSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/PharmacyCardFinderResultSearch"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "PharmacyCardFinder.ResultSearch.PharmacyCardFinderResultSearchResponseModelListResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":[{\"clientId1\":\"string\",\"clientId2\":\"string\",\"clientId3\":\"string\",\"clientId4\":\"string\",\"clientId5\":\"string\",\"quickPathCaseId\":0,\"result\":{\"plan\":[{\"bin\":\"string\",\"cardHolderId\":\"string\",\"familyUnitNumber\":\"string\",\"insurancePriority\":\"string\",\"patientDateOfBirth\":\"string\",\"patientFirstName\":\"string\",\"patientLastName\":\"string\",\"patientMiddleName\":\"string\",\"patientPrefix\":\"string\",\"patientSuffix\":\"string\",\"patientZipCode\":\"string\",\"pbmPayerName\":\"string\",\"pbmPhoneNumber\":\"string\",\"pbmResponseMessage\":\"string\",\"pcn\":\"string\",\"rxGroupId\":\"string\",\"rxGroupName\":\"string\"}],\"prescriberNpi\":\"string\",\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true}}],\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Success but no content"
    status_code = 204
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_PharmacyCardFinderRequestSearch_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "PharmacyCardFinderRequestSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_PharmacyCardFinderRequestSearch_RequestSearch,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_PharmacyCardFinderResultSearch_RequestSearch" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "PharmacyCardFinderResultSearch_RequestSearch"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_PharmacyCardFinderResultSearch_RequestSearch,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_PharmacyCardFinderResultSearch_RequestSearch" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_PharmacyCardFinderResultSearch_RequestSearch.id
#   display_name     = "PharmacyCardFinder"
#   name             = "PharmacyCardFinder"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_PharmacyCardFinderResultSearch_RequestSearch,
#   ]
# }
resource "azurerm_api_management_api_operation" "api_operation_PharmacyCardFinder_Get" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  description         = "Get pharmacy card finder"
  display_name        = "Get pharmacy card finder"
  method              = "POST"
  operation_id        = "PharmacyCardFinder_Get"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/PharmacyCardFinder"
  response {
    description = "Success"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6387c04901234e0e6c2b5569"
    #   type_name    = "PharmacyCardFinder.PharmacyCardFinderResponseModelResponseModel"
    #   example {
    #     name  = "default"
    #     value = "{\"data\":{\"plan\":[{\"bin\":\"string\",\"cardHolderId\":\"string\",\"familyUnitNumber\":\"string\",\"insurancePriority\":\"string\",\"patientDateOfBirth\":\"string\",\"patientFirstName\":\"string\",\"patientLastName\":\"string\",\"patientMiddleName\":\"string\",\"patientPrefix\":\"string\",\"patientSuffix\":\"string\",\"patientZipCode\":\"string\",\"pbmPayerName\":\"string\",\"pbmPhoneNumber\":\"string\",\"pbmResponseMessage\":\"string\",\"pcn\":\"string\",\"rxGroupId\":\"string\",\"rxGroupName\":\"string\"}],\"prescriberNpi\":\"string\",\"transactionCorrelationId\":0,\"transactionDateTime\":\"string\",\"transactionId\":\"string\",\"transactionMessage\":\"string\",\"transactionStatus\":true},\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   type_name    = "ResponseModel"
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_PharmacyCardFinder_Get" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  operation_id        = "PharmacyCardFinder_Get"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="@{ return "eservices" + context.Operation.UrlTemplate + "/" + context.Variables.GetValueOrDefault<string>("programId"); }" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
EOT
  depends_on = [
    azurerm_api_management_api_operation.api_operation_PharmacyCardFinder_Get,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_taPharmacyCardFinder_Get" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_PharmacyCardFinder_Get.id
#   display_name     = "PharmacyCardFinder"
#   name             = "PharmacyCardFinder"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_PharmacyCardFinder_Get,
#   ]
# }
resource "azurerm_api_management_api_policy" "api_management_policy_eservices-orchestrator" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "eservices-orchestrator"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <set-variable name="programId" value="{{eservices-orchestrator-programid}}" />
        <!--
        Currently networking is not setup correctly for APIM, using the docker container as a poor mans proxy for now
        <set-backend-service backend-id="eservices-orchestrator" />
        -->
        <set-backend-service id="apim-generated-policy" backend-id="salesforce-intsvc" />
        <base />
        <set-variable name="audienceId" value="{{eservices-orchestrator-audience}}" />
        <include-fragment fragment-id="access-service-token-cache" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
        </set-header>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>  
EOT
  depends_on = [
    azurerm_api_management_api.api_eservices_orchestrator,
    azurerm_api_management_backend.api_management_backend_salesforce_intsvc,
    azapi_resource.access-service-token-cache-fragment
  ]
}
# resource "azurerm_api_management_api_schema" "api_schema_6387c04901234e0e6c2b5569" {
#   api_management_name = data.azurerm_api_management.apim.name
#   api_name            = "eservices-orchestrator"
#   components          = "{\"schemas\":{\"BaseResponseModel\":{\"description\":\"Base response model\",\"properties\":{\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"BaseResponseModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/BaseResponseModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"Configuration-id-GetRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"Configuration-id-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"Configuration.ExternalSystemModel\":{\"description\":\"External system model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"Configuration.ProgramModel\":{\"description\":\"Program model\",\"properties\":{\"description\":{\"description\":\"Description\",\"nullable\":true,\"type\":\"string\"},\"externalSystem\":{\"$ref\":\"#/components/schemas/Configuration.ExternalSystemModel\"},\"externalSystemId\":{\"description\":\"External System Id\",\"nullable\":true,\"type\":\"string\"},\"id\":{\"description\":\"Id\",\"format\":\"uuid\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"},\"programNdcs\":{\"description\":\"Program Ndcs\",\"items\":{\"$ref\":\"#/components/schemas/Configuration.ProgramNdcModel\"},\"nullable\":true,\"type\":\"array\"},\"programServices\":{\"description\":\"Program Services\",\"items\":{\"$ref\":\"#/components/schemas/Configuration.ProgramServiceModel\"},\"nullable\":true,\"type\":\"array\"}},\"type\":\"object\"},\"Configuration.ProgramModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/Configuration.ProgramModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"Configuration.ProgramNdcModel\":{\"description\":\"Program Ndc model\",\"properties\":{\"id\":{\"description\":\"Program Ndc Id\",\"format\":\"uuid\",\"nullable\":true,\"type\":\"string\"},\"ndcId\":{\"description\":\"NdcId\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"Configuration.ProgramServiceModel\":{\"description\":\"Program Service Model\",\"properties\":{\"id\":{\"description\":\"Program Service Id\",\"format\":\"uuid\",\"nullable\":true,\"type\":\"string\"},\"service\":{\"$ref\":\"#/components/schemas/Configuration.ServiceModel\"}},\"type\":\"object\"},\"Configuration.ServiceModel\":{\"description\":\"Service model\",\"properties\":{\"id\":{\"description\":\"Service Id\",\"format\":\"uuid\",\"type\":\"string\"},\"isAsync\":{\"description\":\"Is async\",\"type\":\"boolean\"},\"serviceProvider\":{\"$ref\":\"#/components/schemas/Configuration.ServiceProviderModel\"},\"serviceType\":{\"$ref\":\"#/components/schemas/Configuration.ServiceTypeModel\"}},\"type\":\"object\"},\"Configuration.ServiceProviderModel\":{\"description\":\"Service provider model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"Configuration.ServiceTypeModel\":{\"description\":\"Service type model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ConfigurationPostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"DefaultGetRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"DefaultPutRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystem-Code-GetRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystem-Code-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystem-code-PutRequest\":{\"description\":\"\",\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystem-code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystemActivate-Code-PutRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystemActivate-Code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystemCreateModel\":{\"description\":\"External system create model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ExternalSystemDeactivate-Code-PutRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystemDeactivate-Code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystemGetRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystemModel\":{\"description\":\"External system model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ExternalSystemModelIEnumerableResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/ExternalSystemModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ExternalSystemModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/ExternalSystemModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ExternalSystemPostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ExternalSystemUpdateModel\":{\"description\":\"External system update model\",\"properties\":{\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"FinancialScreening.FinancialScreeningAddressModel\":{\"description\":\"Address\",\"properties\":{\"address1\":{\"description\":\"Gets or sets the address 1\",\"nullable\":true,\"type\":\"string\"},\"address2\":{\"description\":\"Gets or sets the address 2\",\"nullable\":true,\"type\":\"string\"},\"city\":{\"description\":\"Gets or sets the city\",\"nullable\":true,\"type\":\"string\"},\"state\":{\"description\":\"Gets or sets the state\",\"nullable\":true,\"type\":\"string\"},\"zipCode\":{\"description\":\"Gets or sets the zip code\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"FinancialScreening.FinancialScreeningPatientModel\":{\"description\":\"Patient\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningAddressModel\"},\"birthDate\":{\"description\":\"Gets or sets the birth date\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"gender\":{\"description\":\"Gets or sets the gender\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"middleName\":{\"description\":\"Gets or sets the middle name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"FinancialScreening.FinancialScreeningPrescriberModel\":{\"description\":\"Prescriber\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningAddressModel\"},\"fax\":{\"description\":\"Gets or sets the fax\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the NPI\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the phone\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"FinancialScreening.FinancialScreeningPrescriptionModel\":{\"description\":\"Prescription\",\"properties\":{\"drug\":{\"description\":\"Gets or sets the drug\",\"nullable\":true,\"type\":\"string\"},\"ndc\":{\"description\":\"Gets or sets the NDC\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"FinancialScreening.FinancialScreeningRequestModel\":{\"description\":\"Financial Screening Request\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"patient\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningPatientModel\"},\"prescriber\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningPrescriberModel\"},\"prescription\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningPrescriptionModel\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"FinancialScreening.FinancialScreeningResponseModel\":{\"description\":\"Financial Screening Response Model\",\"properties\":{\"customerID\":{\"description\":\"Gets or sets the Transaction Status.\",\"nullable\":true,\"type\":\"string\"},\"eligibilityStatus\":{\"description\":\"Gets or sets the EligibilityStatus.\",\"nullable\":true,\"type\":\"boolean\"},\"fpl\":{\"description\":\"Gets or sets the FPL.\",\"nullable\":true,\"type\":\"string\"},\"householdEstimatedIncome\":{\"description\":\"Gets or sets the HouseholdEstimatedIncome.\",\"nullable\":true,\"type\":\"string\"},\"householdEstimatedSize\":{\"description\":\"Gets or sets the HouseholdEstimatedSize.\",\"nullable\":true,\"type\":\"string\"},\"requestId\":{\"description\":\"Gets or sets the RequestId\",\"format\":\"int64\",\"type\":\"integer\"},\"resultId\":{\"description\":\"Gets or sets the ResultId\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"FinancialScreening.FinancialScreeningResponseModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningResponseModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"FinancialScreening.RequestSearch.FinancialScreeningRequestSearchModel\":{\"description\":\"Financial Screening Request Search\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"FinancialScreening.RequestSearch.FinancialScreeningRequestSearchResponseModel\":{\"description\":\"Financial Screening Request Search Response\",\"properties\":{\"request\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningRequestModel\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"FinancialScreening.RequestSearch.FinancialScreeningRequestSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/FinancialScreening.RequestSearch.FinancialScreeningRequestSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"FinancialScreening.ResultSearch.FinancialScreeningResultSearchModel\":{\"description\":\"Financial Screening Result Search\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"FinancialScreening.ResultSearch.FinancialScreeningResultSearchResponseModel\":{\"description\":\"Financial Screening Result Search Response\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"result\":{\"$ref\":\"#/components/schemas/FinancialScreening.FinancialScreeningResponseModel\"}},\"type\":\"object\"},\"FinancialScreening.ResultSearch.FinancialScreeningResultSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/FinancialScreening.ResultSearch.FinancialScreeningResultSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"GetRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"GuidListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"format\":\"uuid\",\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"GuidNullableResponseModel\":{\"properties\":{\"data\":{\"format\":\"uuid\",\"nullable\":true,\"type\":\"string\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"GuidResponseModel\":{\"properties\":{\"data\":{\"format\":\"uuid\",\"type\":\"string\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"Logging-Id-GetRequest\":{\"format\":\"int64\",\"type\":\"integer\",\"x-apim-inline\":true},\"Logging-Id-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"LoggingDetailModel\":{\"description\":\"Program model\",\"properties\":{\"id\":{\"description\":\"Logging Detail Id\",\"format\":\"int64\",\"type\":\"integer\"},\"requestOn\":{\"description\":\"Request On\",\"format\":\"date-time\",\"type\":\"string\"},\"responseOn\":{\"description\":\"Response On\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"serviceId\":{\"description\":\"Service Id\",\"format\":\"uuid\",\"nullable\":true,\"type\":\"string\"},\"serviceProviderCode\":{\"description\":\"Service Provider Code\",\"nullable\":true,\"type\":\"string\"},\"serviceProviderName\":{\"description\":\"Service Provider Name\",\"nullable\":true,\"type\":\"string\"},\"serviceTypeCode\":{\"description\":\"Service Type Code\",\"nullable\":true,\"type\":\"string\"},\"serviceTypeName\":{\"description\":\"Service Type Name\",\"nullable\":true,\"type\":\"string\"},\"success\":{\"description\":\"Success\",\"nullable\":true,\"type\":\"boolean\"}},\"type\":\"object\"},\"LoggingModel\":{\"description\":\"Program model\",\"properties\":{\"controllerMethod\":{\"description\":\"Controller Method\",\"nullable\":true,\"type\":\"string\"},\"details\":{\"description\":\"Logging Details Model\",\"items\":{\"$ref\":\"#/components/schemas/LoggingDetailModel\"},\"nullable\":true,\"type\":\"array\"},\"externalSystemCode\":{\"description\":\"External System Code\",\"nullable\":true,\"type\":\"string\"},\"externalSystemId\":{\"description\":\"External System Id\",\"nullable\":true,\"type\":\"string\"},\"id\":{\"description\":\"Logging Id\",\"format\":\"int64\",\"type\":\"integer\"},\"ndc\":{\"description\":\"NDC\",\"nullable\":true,\"type\":\"string\"},\"pharmacyNpi\":{\"description\":\"Pharmacy NPI\",\"nullable\":true,\"type\":\"string\"},\"programDescription\":{\"description\":\"Program Description\",\"nullable\":true,\"type\":\"string\"},\"programFlowId\":{\"description\":\"Program Flow Id\",\"format\":\"uuid\",\"nullable\":true,\"type\":\"string\"},\"programId\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\"},\"programName\":{\"description\":\"Program Name\",\"nullable\":true,\"type\":\"string\"},\"requestData\":{\"description\":\"Request Data\",\"nullable\":true,\"type\":\"string\"},\"requestOn\":{\"description\":\"Request On\",\"format\":\"date-time\",\"type\":\"string\"},\"responseData\":{\"description\":\"Response Data\",\"nullable\":true,\"type\":\"string\"},\"responseOn\":{\"description\":\"Response On\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"statusCode\":{\"description\":\"Status Code\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"LoggingModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/LoggingModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"LoggingModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/LoggingModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"LoggingPostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"LoggingSearchRequestModel\":{\"description\":\"Logging srarch request model\",\"properties\":{\"from\":{\"description\":\"Search From\",\"format\":\"date-time\",\"type\":\"string\"},\"to\":{\"description\":\"Search To\",\"format\":\"date-time\",\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalBi-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalBi.MedicalBiAddressModel\":{\"description\":\"Medical BI Request Address\",\"properties\":{\"address1\":{\"description\":\"Gets or sets the address 1\",\"nullable\":true,\"type\":\"string\"},\"address2\":{\"description\":\"Gets or sets the address 2\",\"nullable\":true,\"type\":\"string\"},\"city\":{\"description\":\"Gets or sets the city\",\"nullable\":true,\"type\":\"string\"},\"state\":{\"description\":\"Gets or sets the state\",\"nullable\":true,\"type\":\"string\"},\"zipCode\":{\"description\":\"Gets or sets the zip code\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiAppealModel\":{\"description\":\"Appeal\",\"properties\":{\"available\":{\"description\":\"Gets or sets available\",\"nullable\":true,\"type\":\"string\"},\"contactFax\":{\"description\":\"Gets or sets contact fax\",\"nullable\":true,\"type\":\"string\"},\"contactOrg\":{\"description\":\"Gets or sets contact org\",\"nullable\":true,\"type\":\"string\"},\"contactPhone\":{\"description\":\"Gets or sets contact phone\",\"nullable\":true,\"type\":\"string\"},\"numberAvailable\":{\"description\":\"Gets or sets the number of appeals available.\",\"nullable\":true,\"type\":\"string\"},\"requiredDocuments\":{\"description\":\"Gets or sets required documents\",\"nullable\":true,\"type\":\"string\"},\"submissionDeadline\":{\"description\":\"Gets or sets submission deadline\",\"nullable\":true,\"type\":\"string\"},\"turnaroundTime\":{\"description\":\"Gets or sets turnaround time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiCodeRequestModel\":{\"description\":\"Code Details\",\"properties\":{\"code\":{\"description\":\"Gets or sets the cpt code\",\"nullable\":true,\"type\":\"string\"},\"unit\":{\"description\":\"Gets or sets the code unit\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiCodeResultModel\":{\"description\":\"Code Details\",\"properties\":{\"coInsurance\":{\"description\":\"Gets or sets the CoInsurance\",\"nullable\":true,\"type\":\"string\"},\"code\":{\"description\":\"Gets or sets the cpt code\",\"nullable\":true,\"type\":\"string\"},\"copay\":{\"description\":\"Gets or sets the Copay\",\"nullable\":true,\"type\":\"string\"},\"deductibleApplies\":{\"description\":\"Gets or sets the Deductible Applies\",\"nullable\":true,\"type\":\"boolean\"},\"notes\":{\"description\":\"Gets or sets the Notes\",\"nullable\":true,\"type\":\"string\"},\"priorAuthorizationRequired\":{\"description\":\"Gets or sets the Prior Authorization Required\",\"nullable\":true,\"type\":\"boolean\"},\"unit\":{\"description\":\"Gets or sets the code unit\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiCopayModel\":{\"description\":\"Copay\",\"properties\":{\"appliesToOop\":{\"description\":\"Gets or sets applies to oop\",\"nullable\":true,\"type\":\"string\"},\"copay\":{\"description\":\"Gets or sets copay\",\"nullable\":true,\"type\":\"string\"},\"notes\":{\"description\":\"Gets or sets notes\",\"nullable\":true,\"type\":\"string\"},\"waivedAfterOpp\":{\"description\":\"Gets or sets waiver after opp\",\"nullable\":true,\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiDenialModel\":{\"description\":\"Denial\",\"properties\":{\"date\":{\"description\":\"Gets or sets the date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"number\":{\"description\":\"Gets or sets number\",\"nullable\":true,\"type\":\"string\"},\"reason\":{\"description\":\"Gets or sets reason\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiDiagnosisModel\":{\"description\":\"Medical BI Request Diagnosis\",\"properties\":{\"cptCodes\":{\"description\":\"Gets or sets the CPT Codes\",\"items\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiCodeRequestModel\"},\"nullable\":true,\"type\":\"array\"},\"jCodes\":{\"description\":\"Gets or sets the J Codes\",\"items\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiCodeRequestModel\"},\"nullable\":true,\"type\":\"array\"},\"primaryIcdCode\":{\"description\":\"Gets or sets the primary ICD code\",\"nullable\":true,\"type\":\"string\"},\"primaryIcdDescription\":{\"description\":\"Gets or sets the primary ICD description\",\"nullable\":true,\"type\":\"string\"},\"secondaryIcdCode\":{\"description\":\"Gets or sets the secondary ICD code\",\"nullable\":true,\"type\":\"string\"},\"secondaryIcdDescription\":{\"description\":\"Gets or sets the secondary ICD description\",\"nullable\":true,\"type\":\"string\"},\"treatmentDate\":{\"description\":\"Gets or sets the treatment date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiFacilityModel\":{\"description\":\"Facility\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAddressModel\"},\"fax\":{\"description\":\"Gets or sets the fax\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Gets or sets the name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the NPI\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the phone\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiFamilyModel\":{\"description\":\"Family\",\"properties\":{\"deductibleMet\":{\"description\":\"Gets or sets deductible met\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"deductibleTotal\":{\"description\":\"Gets or sets deductible total\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"oopMax\":{\"description\":\"Gets or sets oop max\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"oopMet\":{\"description\":\"Gets or sets oop met\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiIndividualModel\":{\"description\":\"Individual\",\"properties\":{\"deductibleMet\":{\"description\":\"Gets or sets deductible met\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"deductibleTotal\":{\"description\":\"Gets or sets deductible total\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"oopMax\":{\"description\":\"Gets or sets oop max\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"oopMet\":{\"description\":\"Gets or sets oop met\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiLifetimeModel\":{\"description\":\"Lifetime\",\"properties\":{\"maxAmount\":{\"description\":\"Gets or sets max amount\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"maxMet\":{\"description\":\"Gets or sets max met\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"maximumExists\":{\"description\":\"Gets or sets maximum exists\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiMedicalModel\":{\"description\":\"Medical\",\"properties\":{\"groupName\":{\"description\":\"Gets or sets group name\",\"nullable\":true,\"type\":\"string\"},\"groupPhone\":{\"description\":\"Gets or sets group phone number\",\"nullable\":true,\"type\":\"string\"},\"policyAvailableOnWebsite\":{\"description\":\"Gets or sets policy available on website\",\"nullable\":true,\"type\":\"string\"},\"policyNumber\":{\"description\":\"Gets or sets policy number\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiModel\":{\"description\":\"Medical BI Request\",\"properties\":{\"chainPbm\":{\"description\":\"Gets or sets the Chain PBM\",\"nullable\":true,\"type\":\"boolean\"},\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"diagnosis\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiDiagnosisModel\"},\"facility\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiFacilityModel\"},\"patient\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPatientRequestModel\"},\"payor\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPayorRequestModel\"},\"practice\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPracticeRequestModel\"},\"preferredSpecialtyPharmacy\":{\"description\":\"Gets or sets the preferred specialty pharmacy\",\"nullable\":true,\"type\":\"boolean\"},\"prescriber\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPrescriberRequestModel\"},\"prescription\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPrescriptionModel\"},\"providerProgramId\":{\"description\":\"Gets or sets the ProviderProgramId\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"specialtyPharmacyName\":{\"description\":\"Gets or sets the specialty pharmacy name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiObtainPreDeterminationModel\":{\"description\":\"Obtain Pre Determination\",\"properties\":{\"fax\":{\"description\":\"Gets or sets fax\",\"nullable\":true,\"type\":\"string\"},\"org\":{\"description\":\"Gets or sets org\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone\",\"nullable\":true,\"type\":\"string\"},\"website\":{\"description\":\"Gets or sets website\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiObtainPriorAuthorizationModel\":{\"description\":\"Obtain Prior Authorization\",\"properties\":{\"fax\":{\"description\":\"Gets or sets fax\",\"nullable\":true,\"type\":\"string\"},\"org\":{\"description\":\"Gets or sets org\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone\",\"nullable\":true,\"type\":\"string\"},\"requirements\":{\"description\":\"Gets or sets requirements\",\"nullable\":true,\"type\":\"string\"},\"website\":{\"description\":\"Gets or sets website\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPatientRequestModel\":{\"description\":\"Patient\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAddressModel\"},\"birthDate\":{\"description\":\"Gets or sets the birth date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"gender\":{\"description\":\"Gets or sets the gender\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"middleName\":{\"description\":\"Gets or sets the middle name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPatientResultModel\":{\"description\":\"Patient\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAddressModel\"},\"birthDate\":{\"description\":\"Gets or sets the birth date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"gender\":{\"description\":\"Gets or sets the gender\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"middleName\":{\"description\":\"Gets or sets the middle name\",\"nullable\":true,\"type\":\"string\"},\"receivesSubsidies\":{\"description\":\"Gets or sets the receives subsidies.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPayorRequestModel\":{\"description\":\"Payor Model\",\"properties\":{\"groupId\":{\"description\":\"Gets or sets the group ID\",\"nullable\":true,\"type\":\"string\"},\"groupName\":{\"description\":\"Gets or sets the group name\",\"nullable\":true,\"type\":\"string\"},\"id\":{\"description\":\"Gets or sets the payor ID\",\"nullable\":true,\"type\":\"string\"},\"memberId\":{\"description\":\"Gets or sets the member ID\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Gets or sets the name\",\"nullable\":true,\"type\":\"string\"},\"otherInsuranceStatus\":{\"description\":\"Gets or sets the other insurance status\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPayorResultModel\":{\"description\":\"Payor Model\",\"properties\":{\"agentName\":{\"description\":\"Gets or sets agent name\",\"nullable\":true,\"type\":\"string\"},\"groupId\":{\"description\":\"Gets or sets the group ID\",\"nullable\":true,\"type\":\"string\"},\"groupName\":{\"description\":\"Gets or sets the group name\",\"nullable\":true,\"type\":\"string\"},\"hasSecondaryInsurance\":{\"description\":\"Gets or sets has secondary insurance\",\"nullable\":true,\"type\":\"boolean\"},\"hasStandardPlanLetter\":{\"description\":\"Gets or sets the has standard plan letter.\",\"nullable\":true,\"type\":\"boolean\"},\"id\":{\"description\":\"Gets or sets the payor ID\",\"nullable\":true,\"type\":\"string\"},\"inNetworkConsideration\":{\"description\":\"Gets or sets the in network consideration.\",\"nullable\":true,\"type\":\"string\"},\"isAccumulatorPlan\":{\"description\":\"Gets or sets the is accumulator plan.\",\"nullable\":true,\"type\":\"boolean\"},\"isMaximizerPlan\":{\"description\":\"Gets or sets the is maximizer plan.\",\"nullable\":true,\"type\":\"boolean\"},\"memberId\":{\"description\":\"Gets or sets the member ID\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Gets or sets the name\",\"nullable\":true,\"type\":\"string\"},\"newPlanAvailable\":{\"description\":\"Gets or sets New Plan Available\",\"nullable\":true,\"type\":\"boolean\"},\"newPlanEffectiveDate\":{\"description\":\"Gets or sets new plan effective date\",\"nullable\":true,\"type\":\"string\"},\"newPlanSubscriberId\":{\"description\":\"Creates new plansubscriberid.\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone number\",\"nullable\":true,\"type\":\"string\"},\"planEffectiveDate\":{\"description\":\"Gets or sets plan effective date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"planFundType\":{\"description\":\"Gets or sets plan fund type\",\"nullable\":true,\"type\":\"string\"},\"planName\":{\"description\":\"Gets or sets the plan name\",\"nullable\":true,\"type\":\"string\"},\"planPriority\":{\"description\":\"Gets or sets plan priority\",\"format\":\"int32\",\"nullable\":true,\"type\":\"integer\"},\"planRenewalMonth\":{\"description\":\"Gets or sets plan renewal month\",\"nullable\":true,\"type\":\"string\"},\"planRenewalType\":{\"description\":\"Gets or sets plan renewal type\",\"nullable\":true,\"type\":\"string\"},\"planTerminationDate\":{\"description\":\"Gets or sets plan termination date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"planType\":{\"description\":\"Gets or sets plan type\",\"nullable\":true,\"type\":\"string\"},\"policyType\":{\"description\":\"Gets or sets policy type\",\"nullable\":true,\"type\":\"string\"},\"referenceId\":{\"description\":\"Gets or sets reference id\",\"nullable\":true,\"type\":\"string\"},\"secondaryInsuranceName\":{\"description\":\"Gets or sets secondary insurance name\",\"nullable\":true,\"type\":\"string\"},\"standardPlanLetter\":{\"description\":\"Gets or sets the standard plan letter.\",\"nullable\":true,\"type\":\"string\"},\"willCoverIfPrimaryDenies\":{\"description\":\"Gets or sets the will cover if primary denies.\",\"nullable\":true,\"type\":\"string\"},\"willCoverPartBDeductible\":{\"description\":\"Gets or sets the will cover part b deductible.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPbmModel\":{\"description\":\"PBM\",\"properties\":{\"exists\":{\"description\":\"Gets or sets exists\",\"nullable\":true,\"type\":\"boolean\"},\"name\":{\"description\":\"Gets or sets name\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPcpModel\":{\"description\":\"PCP\",\"properties\":{\"name\":{\"description\":\"Gets or sets name\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPeerToPeerModel\":{\"description\":\"Peer to Peer\",\"properties\":{\"available\":{\"description\":\"Gets or sets available\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone\",\"nullable\":true,\"type\":\"string\"},\"submissionDeadline\":{\"description\":\"Gets or sets submission deadline\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPlanModel\":{\"description\":\"Plan\",\"properties\":{\"gracePeriod\":{\"description\":\"Gets or sets the grace period\",\"nullable\":true,\"type\":\"string\"},\"isSet\":{\"description\":\"Gets or sets is set\",\"nullable\":true,\"type\":\"boolean\"},\"paidThroughDate\":{\"description\":\"Gets or sets the paid through date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPracticeRequestModel\":{\"description\":\"Medical BI Request Practice\",\"properties\":{\"additionalId\":{\"description\":\"Gets or sets the additional ID\",\"nullable\":true,\"type\":\"string\"},\"address\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAddressModel\"},\"name\":{\"description\":\"Gets or sets the name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the npi\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the phone\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the tax ID\",\"nullable\":true,\"type\":\"string\"},\"type\":{\"description\":\"Gets or sets type\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPracticeResultModel\":{\"description\":\"Medical BI Result Practice\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAddressModel\"},\"name\":{\"description\":\"Gets or sets the name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the npi\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the phone\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the tax ID\",\"nullable\":true,\"type\":\"string\"},\"type\":{\"description\":\"Gets or sets type\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPreDeterminationModel\":{\"description\":\"Pre Determination\",\"properties\":{\"approvedQuantity\":{\"description\":\"Gets or sets Pre-Determination Approved Quantity\",\"nullable\":true,\"type\":\"string\"},\"approvedQuantityUsed\":{\"description\":\"Gets or sets Pre-Determination Approved Quantity Used\",\"nullable\":true,\"type\":\"string\"},\"available\":{\"description\":\"Gets or sets available\",\"nullable\":true,\"type\":\"boolean\"},\"endDate\":{\"description\":\"Gets or sets end date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"number\":{\"description\":\"Gets or sets number\",\"nullable\":true,\"type\":\"string\"},\"onFile\":{\"description\":\"Gets or sets on files\",\"nullable\":true,\"type\":\"boolean\"},\"renewalProcessExists\":{\"description\":\"Gets or sets Pre-Determination Renewal Process Exists\",\"nullable\":true,\"type\":\"boolean\"},\"required\":{\"description\":\"Gets or sets required\",\"nullable\":true,\"type\":\"boolean\"},\"requirement\":{\"description\":\"Gets or sets requirement\",\"nullable\":true,\"type\":\"string\"},\"startDate\":{\"description\":\"Gets or sets start date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"turnaroundTime\":{\"description\":\"Gets or sets turnaround time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPreferredSpecialtyModel\":{\"description\":\"Preferred Specialty\",\"properties\":{\"pharmacy\":{\"description\":\"Gets or sets pharmacy\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPrescriberRequestModel\":{\"description\":\"Medical BI Request Prescriber\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAddressModel\"},\"fax\":{\"description\":\"Gets or sets the fax\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the NPI\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the tax identifier\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPrescriberResultModel\":{\"description\":\"Medical BI Request Prescriber\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAddressModel\"},\"fax\":{\"description\":\"Gets or sets the fax\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"inNetwork\":{\"description\":\"Gets or sets the in network\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the NPI\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the tax identifier\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPrescriptionModel\":{\"description\":\"Medical BI Request Prescription\",\"properties\":{\"daySupply\":{\"description\":\"Gets or sets the day supply\",\"nullable\":true,\"type\":\"string\"},\"drug\":{\"description\":\"Gets or sets the drug\",\"nullable\":true,\"type\":\"string\"},\"ndc\":{\"description\":\"Gets or sets the NDC\",\"nullable\":true,\"type\":\"string\"},\"quantity\":{\"description\":\"Gets or sets the quantity\",\"nullable\":true,\"type\":\"string\"},\"refill\":{\"description\":\"Gets or sets the refill\",\"nullable\":true,\"type\":\"string\"},\"sig\":{\"description\":\"Gets or sets the SIG\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiPriorAuthorizationModel\":{\"description\":\"Prior Authorization\",\"properties\":{\"approvalNumber\":{\"description\":\"Gets or sets approval number\",\"nullable\":true,\"type\":\"string\"},\"approvedQuantity\":{\"description\":\"Gets or sets approval quantity\",\"nullable\":true,\"type\":\"string\"},\"approvedQuantityUsed\":{\"description\":\"Gets or sets approval quantity used\",\"nullable\":true,\"type\":\"string\"},\"endDate\":{\"description\":\"Gets or sets end date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"onFile\":{\"description\":\"Gets or sets on file\",\"nullable\":true,\"type\":\"boolean\"},\"renewalProcessExists\":{\"description\":\"Gets or sets renewwal process exists\",\"nullable\":true,\"type\":\"boolean\"},\"required\":{\"description\":\"Gets or sets required\",\"nullable\":true,\"type\":\"boolean\"},\"requiredCodes\":{\"description\":\"Gets or sets required codes\",\"nullable\":true,\"type\":\"string\"},\"responsibleOrg\":{\"description\":\"Gets or sets responsible org\",\"nullable\":true,\"type\":\"string\"},\"startDate\":{\"description\":\"Gets or sets start date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"status\":{\"description\":\"Gets or sets status\",\"nullable\":true,\"type\":\"string\"},\"turnaroundTime\":{\"description\":\"Gets or sets turnaround time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiReferralModel\":{\"description\":\"Referral\",\"properties\":{\"effectiveDate\":{\"description\":\"Gets or sets effective date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"number\":{\"description\":\"Gets or sets number\",\"nullable\":true,\"type\":\"string\"},\"onFile\":{\"description\":\"Gets or sets on file\",\"nullable\":true,\"type\":\"boolean\"},\"recertDate\":{\"description\":\"Gets or sets recert date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"required\":{\"description\":\"Gets or sets required\",\"nullable\":true,\"type\":\"boolean\"},\"requirements\":{\"description\":\"Gets or sets requirements\",\"nullable\":true,\"type\":\"string\"},\"visitsApproved\":{\"description\":\"Gets or sets visits approved\",\"nullable\":true,\"type\":\"string\"},\"visitsUsed\":{\"description\":\"Gets or sets visits used\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiResponseModel\":{\"description\":\"Medical BI Request Response\",\"properties\":{\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiResponseModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiResponseModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiSpecialtyPharmacyModel\":{\"description\":\"Specialty Pharmacy\",\"properties\":{\"available\":{\"description\":\"Gets or sets available\",\"nullable\":true,\"type\":\"string\"},\"coInsurance\":{\"description\":\"Gets or sets coinsurance\",\"nullable\":true,\"type\":\"string\"},\"copay\":{\"description\":\"Gets or sets copay\",\"nullable\":true,\"type\":\"string\"},\"exclusions\":{\"description\":\"Gets or sets exclusions\",\"nullable\":true,\"type\":\"string\"},\"fax\":{\"description\":\"Gets or sets fax\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Gets or sets name\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets phone\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiSpendDownModel\":{\"description\":\"Spend Down\",\"properties\":{\"exist\":{\"description\":\"Gets or sets exist\",\"nullable\":true,\"type\":\"boolean\"},\"met\":{\"description\":\"Gets or sets met\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"total\":{\"description\":\"Gets or sets total\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"}},\"type\":\"object\"},\"MedicalBi.MedicalBiStepTherapyModel\":{\"description\":\"Step Therapy\",\"properties\":{\"required\":{\"description\":\"Gets or sets required\",\"nullable\":true,\"type\":\"boolean\"},\"treatment\":{\"description\":\"Gets or sets treatment\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.RequestSearch.MedicalBiRequestSearchModel\":{\"description\":\"Medical BI Request Search Model\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"MedicalBi.RequestSearch.MedicalBiRequestSearchResponseModel\":{\"description\":\"MedicalBI Request Search Response Model\",\"properties\":{\"request\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiModel\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalBi.RequestSearch.MedicalBiRequestSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/MedicalBi.RequestSearch.MedicalBiRequestSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalBi.ResultSearch.MedicalBiResultSearchModel\":{\"description\":\"Medical BI Result Search Model\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"MedicalBi.ResultSearch.MedicalBiResultSearchResponseDetailModel\":{\"description\":\"MedicalBI Result Search Response Model\",\"properties\":{\"additionalNotes\":{\"description\":\"Gets or sets additional notes\",\"nullable\":true,\"type\":\"string\"},\"annualCap\":{\"description\":\"Gets or sets the cap\",\"nullable\":true,\"type\":\"string\"},\"annualCapExist\":{\"description\":\"Gets or sets annual cap exist\",\"nullable\":true,\"type\":\"boolean\"},\"annualCapMetAmount\":{\"description\":\"Gets or sets the cap met amount.\",\"format\":\"double\",\"nullable\":true,\"type\":\"number\"},\"appeal\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiAppealModel\"},\"benefitNetworkStatus\":{\"description\":\"Gets or sets benefit network status\",\"nullable\":true,\"type\":\"string\"},\"benefitsNotes\":{\"description\":\"Gets or sets benefits notes\",\"nullable\":true,\"type\":\"string\"},\"buyAndBillAvailable\":{\"description\":\"Gets or sets buy and bill available\",\"nullable\":true,\"type\":\"string\"},\"claimAddress\":{\"description\":\"Gets or sets claim address\",\"nullable\":true,\"type\":\"string\"},\"coInsurance\":{\"description\":\"Gets or sets coinsurance\",\"nullable\":true,\"type\":\"string\"},\"cobraPlan\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPlanModel\"},\"coordinationOfBenefits\":{\"description\":\"Gets or sets coordination of benefits\",\"nullable\":true,\"type\":\"string\"},\"copay\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiCopayModel\"},\"cptCodes\":{\"description\":\"Gets or sets CPT Codes\",\"items\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiCodeResultModel\"},\"nullable\":true,\"type\":\"array\"},\"createdTimestamp\":{\"description\":\"Gets or sets created timestamp\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"deductibleApplies\":{\"description\":\"Gets or sets Deductible Applies\",\"nullable\":true,\"type\":\"boolean\"},\"deductibleIncludedInOop\":{\"description\":\"Gets or sets deductible included in oop\",\"nullable\":true,\"type\":\"boolean\"},\"denial\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiDenialModel\"},\"facility\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiFacilityModel\"},\"family\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiFamilyModel\"},\"followsMedicareGuidelines\":{\"description\":\"Gets or sets follows medicare guidelines\",\"nullable\":true,\"type\":\"string\"},\"healthExchangePlan\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPlanModel\"},\"individual\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiIndividualModel\"},\"jCodes\":{\"description\":\"Gets or sets J Codes\",\"items\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiCodeResultModel\"},\"nullable\":true,\"type\":\"array\"},\"lifetime\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiLifetimeModel\"},\"medical\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiMedicalModel\"},\"multipleCopay\":{\"description\":\"Gets or sets multiple copay\",\"nullable\":true,\"type\":\"boolean\"},\"obtainPreDetermination\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiObtainPreDeterminationModel\"},\"obtainPriorAuthorization\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiObtainPriorAuthorizationModel\"},\"patient\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPatientResultModel\"},\"payor\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPayorResultModel\"},\"pbm\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPbmModel\"},\"pcp\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPcpModel\"},\"peerToPeer\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPeerToPeerModel\"},\"practice\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPracticeResultModel\"},\"preDetermination\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPreDeterminationModel\"},\"preferredSpecialty\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPreferredSpecialtyModel\"},\"prescriber\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPrescriberResultModel\"},\"prescription\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPrescriptionModel\"},\"priorAuthorization\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiPriorAuthorizationModel\"},\"reasonForNonCoverage\":{\"description\":\"Gets or sets reason for non-coverage\",\"nullable\":true,\"type\":\"string\"},\"referral\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiReferralModel\"},\"reviewRequired\":{\"description\":\"Gets or sets review required\",\"nullable\":true,\"type\":\"boolean\"},\"specialtyPharmacy\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiSpecialtyPharmacyModel\"},\"spendDown\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiSpendDownModel\"},\"stepTherapy\":{\"$ref\":\"#/components/schemas/MedicalBi.MedicalBiStepTherapyModel\"},\"taskCompletedDate\":{\"description\":\"Gets or sets Task Completed Date\",\"nullable\":true,\"type\":\"string\"},\"taskStatus\":{\"description\":\"Gets or sets task status\",\"nullable\":true,\"type\":\"string\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"},\"updatedTimestamp\":{\"description\":\"Gets or sets updated timestamp\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalBi.ResultSearch.MedicalBiResultSearchResponseModel\":{\"description\":\"MedicalBI Result Search Response Model\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"result\":{\"$ref\":\"#/components/schemas/MedicalBi.ResultSearch.MedicalBiResultSearchResponseDetailModel\"}},\"type\":\"object\"},\"MedicalBi.ResultSearch.MedicalBiResultSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/MedicalBi.ResultSearch.MedicalBiResultSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalBiRequestSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalBiRequestSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalBiResultSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalBiResultSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalEligibility-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalEligibility-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalEligibility.AddressModel\":{\"description\":\"Medical BI Request Address\",\"properties\":{\"address1\":{\"description\":\"Gets or sets the address 1\",\"nullable\":true,\"type\":\"string\"},\"address2\":{\"description\":\"Gets or sets the address 2\",\"nullable\":true,\"type\":\"string\"},\"city\":{\"description\":\"Gets or sets the city\",\"nullable\":true,\"type\":\"string\"},\"state\":{\"description\":\"Gets or sets the state\",\"nullable\":true,\"type\":\"string\"},\"zipCode\":{\"description\":\"Gets or sets the zip code\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalEligibility.MedicalEligibilityRequestModel\":{\"description\":\"Medical Eligibility Request\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"maskedCaseId\":{\"description\":\"Gets or sets the QuickPath Masked Case Id.\",\"nullable\":true,\"type\":\"string\"},\"patient\":{\"$ref\":\"#/components/schemas/MedicalEligibility.PatientRequestModel\"},\"payor\":{\"$ref\":\"#/components/schemas/MedicalEligibility.PayorRequestModel\"},\"practice\":{\"$ref\":\"#/components/schemas/MedicalEligibility.PracticeModel\"},\"prescriber\":{\"$ref\":\"#/components/schemas/MedicalEligibility.PrescriberRequestModel\"},\"programId\":{\"description\":\"Gets or sets the program identifier.\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"treatmentDate\":{\"description\":\"Gets or sets the treatment date.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalEligibility.MedicalEligibilityResponseModel\":{\"description\":\"Medical Eligibility Response\",\"properties\":{\"annualBenefitCap\":{\"description\":\"Gets or sets the Annual Benefit Cap.\",\"nullable\":true,\"type\":\"string\"},\"annualBenefitCapMetAmount\":{\"description\":\"Gets or sets the Annual Benefit Cap Met Amount.\",\"nullable\":true,\"type\":\"string\"},\"coPayAppliesToOop\":{\"description\":\"Gets or sets the CoPay Applies To OOP.\",\"nullable\":true,\"type\":\"string\"},\"copayWaivedAfterOPP\":{\"description\":\"Gets or sets the Copy Waived After OPP.\",\"nullable\":true,\"type\":\"string\"},\"familyCoInsurance\":{\"description\":\"Gets or sets the Family CoInsurance.\",\"nullable\":true,\"type\":\"string\"},\"familyDeductible\":{\"description\":\"Gets or sets the Family Deductible.\",\"nullable\":true,\"type\":\"string\"},\"familyDeductibleMet\":{\"description\":\"Gets or sets the Family Deductible Met.\",\"nullable\":true,\"type\":\"string\"},\"familyDeductibleOutNetwork\":{\"description\":\"Gets or sets the Family Deductible Out Network.\",\"nullable\":true,\"type\":\"string\"},\"familyDeductibleRemaining\":{\"description\":\"Gets or sets the Family Deductible Remaining.\",\"nullable\":true,\"type\":\"string\"},\"familyOop\":{\"description\":\"Gets or sets the Family OOP.\",\"nullable\":true,\"type\":\"string\"},\"familyOopMet\":{\"description\":\"Gets or sets the Family OOP Met.\",\"nullable\":true,\"type\":\"string\"},\"familyOopOutNetwork\":{\"description\":\"Gets or sets the Family OOP Out Network.\",\"nullable\":true,\"type\":\"string\"},\"familyOopRemaining\":{\"description\":\"Gets or sets the Family OOP Remaining.\",\"nullable\":true,\"type\":\"string\"},\"groupId\":{\"description\":\"Gets or sets the group id.\",\"nullable\":true,\"type\":\"string\"},\"groupName\":{\"description\":\"Gets or sets the group name.\",\"nullable\":true,\"type\":\"string\"},\"individualCoInsurance\":{\"description\":\"Gets or sets the individual co-insurance.\",\"nullable\":true,\"type\":\"string\"},\"individualDeductible\":{\"description\":\"Gets or sets the individual deductible.\",\"nullable\":true,\"type\":\"string\"},\"individualDeductibleMet\":{\"description\":\"Gets or sets the individual deductible met.\",\"nullable\":true,\"type\":\"string\"},\"individualDeductibleOutNetwork\":{\"description\":\"Gets or sets the individual Deductible Out Network.\",\"nullable\":true,\"type\":\"string\"},\"individualDeductibleRemaining\":{\"description\":\"Gets or sets the individual deductible remaining.\",\"nullable\":true,\"type\":\"string\"},\"individualDeductibleRemainingOutNetwork\":{\"description\":\"Gets or sets the individual Deductible Remanining Out Network.\",\"nullable\":true,\"type\":\"string\"},\"individualOop\":{\"description\":\"Gets or sets the individual OOP.\",\"nullable\":true,\"type\":\"string\"},\"individualOopMet\":{\"description\":\"Gets or sets the individual OOP Met.\",\"nullable\":true,\"type\":\"string\"},\"individualOopOutNetwork\":{\"description\":\"Gets or sets the individual OOP Out Network.\",\"nullable\":true,\"type\":\"string\"},\"individualOopRemaining\":{\"description\":\"Gets or sets the individual OOP Remaining.\",\"nullable\":true,\"type\":\"string\"},\"individualOopRemainingOutNetwork\":{\"description\":\"Gets or sets the individual OOP Remanining Out Network.\",\"nullable\":true,\"type\":\"string\"},\"insurancePolicyNumber\":{\"description\":\"Gets or sets the Insurance Policy Number.\",\"nullable\":true,\"type\":\"string\"},\"isAccumulatorPlan\":{\"description\":\"Gets or sets the Is Accumulator Plan.\",\"nullable\":true,\"type\":\"string\"},\"isMaximizerPlan\":{\"description\":\"Gets or sets the Is Maximizer Plan.\",\"nullable\":true,\"type\":\"string\"},\"lifetimeMaximumAmount\":{\"description\":\"Gets or sets the Lifetime Maximum Amount.\",\"nullable\":true,\"type\":\"string\"},\"lifetimeMaximumExists\":{\"description\":\"Gets or sets the Lifetime Maximum Exists.\",\"nullable\":true,\"type\":\"string\"},\"lifetimeMaximumMet\":{\"description\":\"Gets or sets the Lifetime Maximum Amount Met.\",\"nullable\":true,\"type\":\"string\"},\"memberId\":{\"description\":\"Gets or sets the member id.\",\"nullable\":true,\"type\":\"string\"},\"patientAddressLine1\":{\"description\":\"Gets or sets the patient address line1.\",\"nullable\":true,\"type\":\"string\"},\"patientAddressLine2\":{\"description\":\"Gets or sets the patient address line2.\",\"nullable\":true,\"type\":\"string\"},\"patientChangeFlag\":{\"description\":\"Gets or sets the Patient Change Flag.\",\"nullable\":true,\"type\":\"boolean\"},\"patientCity\":{\"description\":\"Gets or sets the patient city.\",\"nullable\":true,\"type\":\"string\"},\"patientDateOfBirth\":{\"description\":\"Gets or sets the patient date of birth.\",\"nullable\":true,\"type\":\"string\"},\"patientFirstName\":{\"description\":\"Gets or sets the first name of the patient.\",\"nullable\":true,\"type\":\"string\"},\"patientGender\":{\"description\":\"Gets or sets the patient gender.\",\"nullable\":true,\"type\":\"string\"},\"patientLastName\":{\"description\":\"Gets or sets the last name of the patient.\",\"nullable\":true,\"type\":\"string\"},\"patientMiddleName\":{\"description\":\"Gets or sets the middle name of the patient.\",\"nullable\":true,\"type\":\"string\"},\"patientRelation\":{\"description\":\"Gets or sets the Patient Relation.\",\"nullable\":true,\"type\":\"string\"},\"patientState\":{\"description\":\"Gets or sets the state of the patient.\",\"nullable\":true,\"type\":\"string\"},\"patientZipCode\":{\"description\":\"Gets or sets the patient zip code.\",\"nullable\":true,\"type\":\"string\"},\"payerId\":{\"description\":\"Gets or sets the payer id.\",\"nullable\":true,\"type\":\"string\"},\"payerName\":{\"description\":\"Gets or sets the payer name.\",\"nullable\":true,\"type\":\"string\"},\"payerPhoneNumber\":{\"description\":\"Gets or sets the payer phone number.\",\"nullable\":true,\"type\":\"string\"},\"payerReferenceId\":{\"description\":\"Gets or sets the Payer Reference identifier.\",\"nullable\":true,\"type\":\"string\"},\"pbmExists\":{\"description\":\"Gets or sets the PBM Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"pbmName\":{\"description\":\"Gets or sets the PBM Name.\",\"nullable\":true,\"type\":\"string\"},\"pbmPhoneNumber\":{\"description\":\"Gets or sets the PBM Phone Number.\",\"nullable\":true,\"type\":\"string\"},\"planEffectiveDate\":{\"description\":\"Gets or sets the plan effective date.\",\"nullable\":true,\"type\":\"string\"},\"planName\":{\"description\":\"Gets or sets the plan name.\",\"nullable\":true,\"type\":\"string\"},\"planPriority\":{\"description\":\"Gets or sets the plan priority.\",\"nullable\":true,\"type\":\"string\"},\"planTerminationDate\":{\"description\":\"Gets or sets the plan termination date.\",\"nullable\":true,\"type\":\"string\"},\"planType\":{\"description\":\"Gets or sets the plan type.\",\"nullable\":true,\"type\":\"string\"},\"preferredSpecialtyPharmacy\":{\"description\":\"Gets or sets the preferred specialty pharmacy.\",\"nullable\":true,\"type\":\"string\"},\"preferredSpecialtyPhoneNo\":{\"description\":\"Gets or sets the preferred specialty phone.\",\"nullable\":true,\"type\":\"string\"},\"prescriberAddressLine1\":{\"description\":\"Gets or sets the prescriber address line1.\",\"nullable\":true,\"type\":\"string\"},\"prescriberAddressLine2\":{\"description\":\"Gets or sets the prescriber address line2.\",\"nullable\":true,\"type\":\"string\"},\"prescriberCity\":{\"description\":\"Gets or sets the prescriber city.\",\"nullable\":true,\"type\":\"string\"},\"prescriberFirstName\":{\"description\":\"Gets or sets the first name of the prescriber.\",\"nullable\":true,\"type\":\"string\"},\"prescriberInNetwork\":{\"description\":\"Gets or sets the practice in network.\",\"nullable\":true,\"type\":\"string\"},\"prescriberLastName\":{\"description\":\"Gets or sets the last name of the prescriber.\",\"nullable\":true,\"type\":\"string\"},\"prescriberNpi\":{\"description\":\"Gets or sets the prescriber npi.\",\"nullable\":true,\"type\":\"string\"},\"prescriberState\":{\"description\":\"Gets or sets the state of the prescriber.\",\"nullable\":true,\"type\":\"string\"},\"prescriberTaxId\":{\"description\":\"Gets or sets the prescriber tax id.\",\"nullable\":true,\"type\":\"string\"},\"prescriberZipCode\":{\"description\":\"Gets or sets the prescriber zip code.\",\"nullable\":true,\"type\":\"string\"},\"priorIdentifierNumber\":{\"description\":\"Gets or sets the Prior Identifier Number.\",\"nullable\":true,\"type\":\"string\"},\"programId\":{\"description\":\"Gets or sets the program identifier.\",\"nullable\":true,\"type\":\"string\"},\"secondaryInsuranceExists\":{\"description\":\"Gets or sets the secondary insurance exists.\",\"nullable\":true,\"type\":\"boolean\"},\"secondaryInsuranceName\":{\"description\":\"Gets or sets the secondary insurance name.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyAvailability\":{\"description\":\"Gets or sets the specialty pharmacy Availability.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyCoInsurance\":{\"description\":\"Gets or sets the specialty pharmacy coinsurance.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyCopay\":{\"description\":\"Gets or sets the specialty pharmacy copay.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyName\":{\"description\":\"Gets or sets the specialty pharmacy Name.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyPhoneNumber\":{\"description\":\"Gets or sets the specialty pharmacy Phone.\",\"nullable\":true,\"type\":\"string\"},\"spendDownExists\":{\"description\":\"Gets or sets the Spend Down Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"taskStatus\":{\"description\":\"Gets or sets the Task Status.\",\"nullable\":true,\"type\":\"string\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalEligibility.MedicalEligibilityResponseModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/MedicalEligibility.MedicalEligibilityResponseModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalEligibility.PatientRequestModel\":{\"description\":\"Patient\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalEligibility.AddressModel\"},\"birthDate\":{\"description\":\"Gets or sets the birth date\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"gender\":{\"description\":\"Gets or sets the gender\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"middleName\":{\"description\":\"Gets or sets the middle name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalEligibility.PayorRequestModel\":{\"description\":\"Payor Model\",\"properties\":{\"groupId\":{\"description\":\"Gets or sets the group ID\",\"nullable\":true,\"type\":\"string\"},\"id\":{\"description\":\"Gets or sets the payor ID\",\"nullable\":true,\"type\":\"string\"},\"memberId\":{\"description\":\"Gets or sets the member ID\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Gets or sets the name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalEligibility.PracticeModel\":{\"description\":\"Medical BI Request Practice\",\"properties\":{\"additionalId\":{\"description\":\"Gets or sets the additional ID\",\"nullable\":true,\"type\":\"string\"},\"address\":{\"$ref\":\"#/components/schemas/MedicalEligibility.AddressModel\"},\"name\":{\"description\":\"Gets or sets the name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the npi\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the phone\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the tax ID\",\"nullable\":true,\"type\":\"string\"},\"type\":{\"description\":\"Gets or sets type\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalEligibility.PrescriberRequestModel\":{\"description\":\"Medical BI Request Prescriber\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/MedicalEligibility.AddressModel\"},\"fax\":{\"description\":\"Gets or sets the fax\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the NPI\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the tax identifier\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"MedicalEligibility.RequestSearch.MedicalEligibilityRequestSearchModel\":{\"description\":\"Medical Eligibility Result Search\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"MedicalEligibility.RequestSearch.MedicalEligibilityRequestSearchResponseModel\":{\"description\":\"Medical Eligibility Result Search Response\",\"properties\":{\"request\":{\"$ref\":\"#/components/schemas/MedicalEligibility.MedicalEligibilityRequestModel\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalEligibility.RequestSearch.MedicalEligibilityRequestSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/MedicalEligibility.RequestSearch.MedicalEligibilityRequestSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalEligibility.ResultSearch.MedicalEligibilityResultSearchModel\":{\"description\":\"Medical Eligibility Result Search\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"MedicalEligibility.ResultSearch.MedicalEligibilityResultSearchResponseModel\":{\"description\":\"Medical Eligibility Result Search Response\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"result\":{\"$ref\":\"#/components/schemas/MedicalEligibility.MedicalEligibilityResponseModel\"}},\"type\":\"object\"},\"MedicalEligibility.ResultSearch.MedicalEligibilityResultSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/MedicalEligibility.ResultSearch.MedicalEligibilityResultSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"MedicalEligibilityRequestSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalEligibilityRequestSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalEligibilityResultSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"MedicalEligibilityResultSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyBi-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyBi-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyBi.PharmacyBIPracticeModel\":{\"description\":\"Pharmacy BI Request Practice\",\"properties\":{\"additionalId\":{\"description\":\"Gets or sets the Practice Additional Id\",\"nullable\":true,\"type\":\"string\"},\"address\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiAddressModel\"},\"fax\":{\"description\":\"Gets or sets the Practice Fax Number\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Gets or sets the Practice Name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the Practice Npi\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the Practice Phone Number\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the Practice TaxId\",\"nullable\":true,\"type\":\"string\"},\"type\":{\"description\":\"Gets or sets the Practice Type\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBISpecialtyPharmacyModel\":{\"description\":\"Gets or sets SpecialtyPharmacy\",\"properties\":{\"name\":{\"description\":\"Gets or sets Specialty Pharmacy Name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets Specialty Pharmacy Npi\",\"nullable\":true,\"type\":\"string\"},\"preferred\":{\"description\":\"Gets or sets Preferred Specialty Pharmacy\",\"nullable\":true,\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiAddressModel\":{\"description\":\"Pharmacy BI Request Address\",\"properties\":{\"address1\":{\"description\":\"Gets or sets the address 1\",\"nullable\":true,\"type\":\"string\"},\"address2\":{\"description\":\"Gets or sets the address 2\",\"nullable\":true,\"type\":\"string\"},\"city\":{\"description\":\"Gets or sets the city\",\"nullable\":true,\"type\":\"string\"},\"state\":{\"description\":\"Gets or sets the state\",\"nullable\":true,\"type\":\"string\"},\"zipCode\":{\"description\":\"Gets or sets the zip code\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiDiagnosisModel\":{\"description\":\"Pharmacy BI Request Diagnosis\",\"properties\":{\"jCode\":{\"description\":\"Gets or sets JCode\",\"nullable\":true,\"type\":\"string\"},\"jCodeDescription\":{\"nullable\":true,\"type\":\"string\"},\"primaryIcdCode\":{\"description\":\"Gets or sets the primary ICD code\",\"nullable\":true,\"type\":\"string\"},\"primaryIcdDescription\":{\"description\":\"Gets or sets the primary ICD description\",\"nullable\":true,\"type\":\"string\"},\"secondaryIcdCode\":{\"description\":\"Gets or sets the Secondary ICD description\",\"nullable\":true,\"type\":\"string\"},\"secondaryIcdDescription\":{\"description\":\"Gets or sets the Secondary ICD description\",\"nullable\":true,\"type\":\"string\"},\"treatmentDate\":{\"description\":\"Gets or sets TreatmentDate\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiModel\":{\"description\":\"Pharmacy BI Request\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"diagnosis\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiDiagnosisModel\"},\"patient\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiPatientModel\"},\"payor\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiPayorModel\"},\"pharmacyNPI\":{\"description\":\"Gets or sets the PharmacyNPI\",\"nullable\":true,\"type\":\"string\"},\"practice\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBIPracticeModel\"},\"prescriber\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiPrescriberModel\"},\"prescription\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiPrescriptionModel\"},\"providerProgramId\":{\"description\":\"Gets or sets the ProviderProgramId\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"specialtyPharmacy\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBISpecialtyPharmacyModel\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiPatientModel\":{\"description\":\"Pharmacy BI Request Patient\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiAddressModel\"},\"birthDate\":{\"description\":\"Gets or sets the birth date\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"gender\":{\"description\":\"Gets or sets the gender\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"middleName\":{\"description\":\"Gets or sets the middle name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiPayorModel\":{\"description\":\"Pharmacy BI Request Payor\",\"properties\":{\"bin\":{\"description\":\"Gets or sets the bin\",\"nullable\":true,\"type\":\"string\"},\"cardHolderId\":{\"description\":\"Gets or sets the card holder ID\",\"nullable\":true,\"type\":\"string\"},\"groupId\":{\"description\":\"Gets or sets the group ID\",\"nullable\":true,\"type\":\"string\"},\"groupName\":{\"description\":\"Gets or sets the group name\",\"nullable\":true,\"type\":\"string\"},\"id\":{\"description\":\"Gets or sets the PayerId\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Gets or sets the Payer name\",\"nullable\":true,\"type\":\"string\"},\"otherInsuranceStatus\":{\"description\":\"Gets or sets OtherInsuranceStatus\",\"nullable\":true,\"type\":\"string\"},\"pcn\":{\"description\":\"Gets or sets the pcn\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the Customer Payer Phone\",\"nullable\":true,\"type\":\"string\"},\"planName\":{\"description\":\"Gets or sets PlanName\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiPrescriberModel\":{\"description\":\"Pharmacy BI Request Prescriber\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiAddressModel\"},\"fax\":{\"description\":\"Gets or sets the fax\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name\",\"nullable\":true,\"type\":\"string\"},\"inNetwork\":{\"description\":\"Gets or sets the Prescriber Network Status\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the NPI\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the pghone\",\"nullable\":true,\"type\":\"string\"},\"taxId\":{\"description\":\"Gets or sets the Prescriber Tax Id\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiPrescriptionModel\":{\"description\":\"Pharmacy BI Request Prescription\",\"properties\":{\"daySupply\":{\"description\":\"Gets or sets the day supply\",\"nullable\":true,\"type\":\"string\"},\"drug\":{\"description\":\"Gets or sets the drug\",\"nullable\":true,\"type\":\"string\"},\"ndc\":{\"description\":\"Gets or sets the NDC\",\"nullable\":true,\"type\":\"string\"},\"quantity\":{\"description\":\"Gets or sets the quantity\",\"nullable\":true,\"type\":\"string\"},\"refill\":{\"description\":\"Gets or sets the refill\",\"nullable\":true,\"type\":\"string\"},\"sig\":{\"description\":\"Gets or sets the SIG\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiResponseDetailModel\":{\"description\":\"Pharmacy BI Request Response\",\"properties\":{\"accumulatedDeductibleAmount\":{\"description\":\"Gets or sets the Accumulated Deductible Amount\",\"nullable\":true,\"type\":\"string\"},\"additionalNotes\":{\"description\":\"Gets or sets the PBM Response Message.\",\"nullable\":true,\"type\":\"string\"},\"annualBenefitCap\":{\"description\":\"Gets or sets the Annual Benefit Cap.\",\"nullable\":true,\"type\":\"string\"},\"annualBenefitCapMetAmount\":{\"description\":\"Gets or sets the Annual Benefit Cap Met Amount.\",\"nullable\":true,\"type\":\"string\"},\"annualCapExists\":{\"description\":\"Gets or sets if the Annual Cap Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"appealAvailable\":{\"description\":\"Gets or sets if Appeal Available.\",\"nullable\":true,\"type\":\"string\"},\"appealContactFax\":{\"description\":\"Gets or sets the Appeal Contact Fax.\",\"nullable\":true,\"type\":\"string\"},\"appealContactOrg\":{\"description\":\"Gets or sets the Appeal Contact Org.\",\"nullable\":true,\"type\":\"string\"},\"appealContactPhone\":{\"description\":\"Gets or sets the Appeal Contact Phone.\",\"nullable\":true,\"type\":\"string\"},\"appealsNotificationMethod\":{\"description\":\"Gets or sets the Appeals Notification Method.\",\"nullable\":true,\"type\":\"string\"},\"appealsRequiredDocuments\":{\"description\":\"Gets or sets the Appeals Required Documents.\",\"nullable\":true,\"type\":\"string\"},\"appealsSubmissionDeadline\":{\"description\":\"Gets or sets the Appeals Submission Deadline.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"appealsTurnaroundTime\":{\"description\":\"Gets or sets the Appeals Turnaround Time.\",\"nullable\":true,\"type\":\"string\"},\"bin\":{\"description\":\"Gets or sets the Bin\",\"nullable\":true,\"type\":\"string\"},\"cardHolderId\":{\"description\":\"Gets or sets the card holder ID\",\"nullable\":true,\"type\":\"string\"},\"coPayAppliesToOop\":{\"description\":\"Gets or sets if the CoPay Applies to OOP.\",\"nullable\":true,\"type\":\"boolean\"},\"coordinationOfBenefits\":{\"description\":\"Gets or sets the coordination of benefits.\",\"nullable\":true,\"type\":\"string\"},\"customerId\":{\"description\":\"Gets or sets the Customer Id.\",\"nullable\":true,\"type\":\"string\"},\"daysSupplyPriced\":{\"description\":\"Gets or sets the Days Supply Priced\",\"format\":\"int32\",\"type\":\"integer\"},\"deductibleAppliedAmount\":{\"description\":\"Gets or sets the Deductible Applied Amount\",\"nullable\":true,\"type\":\"string\"},\"deductibleIncludedInOop\":{\"description\":\"Gets or sets if the Deductible Included in OOP.\",\"nullable\":true,\"type\":\"boolean\"},\"deductibleRemainingAmount\":{\"description\":\"Gets or sets the Deductible Remaining Amount\",\"nullable\":true,\"type\":\"string\"},\"denialDate\":{\"description\":\"Gets or sets the Denial Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"denialNotes\":{\"description\":\"Gets or sets the Denial Notes.\",\"nullable\":true,\"type\":\"string\"},\"denialNumber\":{\"description\":\"Gets or sets the Denial Number.\",\"nullable\":true,\"type\":\"string\"},\"denialReason\":{\"description\":\"Gets or sets the Denial Reason.\",\"nullable\":true,\"type\":\"string\"},\"drugCoverageStatus\":{\"description\":\"Gets or sets the drug coverage status\",\"nullable\":true,\"type\":\"string\"},\"estimatedPatientPayAmount\":{\"description\":\"Gets or sets the Estimated Patient Pay Amount\",\"nullable\":true,\"type\":\"string\"},\"familyDeductibleExists\":{\"description\":\"Gets or sets if the Family Deductible Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"familyDeductibleMet\":{\"description\":\"Gets or sets the Family Deductible Met.\",\"nullable\":true,\"type\":\"string\"},\"familyDeductibleTotal\":{\"description\":\"Gets or sets the Family Deductible Total.\",\"nullable\":true,\"type\":\"string\"},\"familyOopMaximum\":{\"description\":\"Gets or sets the Family OOP Maximum.\",\"nullable\":true,\"type\":\"string\"},\"familyOopMaximumExists\":{\"description\":\"Gets or sets if the Family OOP Maximum Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"familyOopMet\":{\"description\":\"Gets or sets the Family OOP Met.\",\"nullable\":true,\"type\":\"string\"},\"familyUnitNumber\":{\"description\":\"Gets or sets the family unit number\",\"nullable\":true,\"type\":\"string\"},\"individualDeductibleExists\":{\"description\":\"Gets or sets if the Individual Deductible Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"individualDeductibleMet\":{\"description\":\"Gets or sets the Accumulated Deductible Amount.\",\"nullable\":true,\"type\":\"string\"},\"individualDeductibleTotal\":{\"description\":\"Gets or sets the Individual Deductible Total.\",\"nullable\":true,\"type\":\"string\"},\"individualOopMaximum\":{\"description\":\"Gets or sets the Individual OOP Maximum.\",\"nullable\":true,\"type\":\"string\"},\"individualOopMaximumExists\":{\"description\":\"Gets or sets if the Individual OOP Maximum Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"individualOopMet\":{\"description\":\"Gets or sets the Accumulated Deductible Amount.\",\"nullable\":true,\"type\":\"string\"},\"initialCoverageLimitMetAmount\":{\"description\":\"Gets or sets the Initial Coverage Limit Met Amount.\",\"nullable\":true,\"type\":\"string\"},\"initialCoverageLimitTotal\":{\"description\":\"Gets or sets the Initial Coverage Limit Total.\",\"nullable\":true,\"type\":\"string\"},\"insurancePriority\":{\"description\":\"Gets or sets the Insurance Priority\",\"nullable\":true,\"type\":\"string\"},\"insuranceType\":{\"description\":\"Gets or sets the insurance type\",\"nullable\":true,\"type\":\"string\"},\"isAccumulatorPlan\":{\"description\":\"Gets or sets if Is Accumulator Plan.\",\"nullable\":true,\"type\":\"boolean\"},\"isMaximizerPlan\":{\"description\":\"Gets or sets if Is Maximizer Plan.\",\"nullable\":true,\"type\":\"boolean\"},\"isOnLowIncomeSubsidy\":{\"description\":\"Gets or sets if Is On Low Income Subsidy.\",\"nullable\":true,\"type\":\"boolean\"},\"lifetimeMaximumAmount\":{\"description\":\"Gets or sets the Lifetime Maximum Amount.\",\"nullable\":true,\"type\":\"string\"},\"lifetimeMaximumExists\":{\"description\":\"Gets or sets if the Lifetime Maximum Exists.\",\"nullable\":true,\"type\":\"boolean\"},\"lifetimeMaximumMet\":{\"description\":\"Gets or sets the Lifetime Maximum Met.\",\"nullable\":true,\"type\":\"string\"},\"lowIncomeSubsidyLevel\":{\"description\":\"Gets or sets the Low Income Subsidy Level.\",\"nullable\":true,\"type\":\"string\"},\"mailOrderPharmacyName\":{\"description\":\"Gets or sets the Mail Order Pharmacy Name.\",\"nullable\":true,\"type\":\"string\"},\"mailOrderPharmacyPhone\":{\"description\":\"Gets or sets the Mail Order Pharmacy Phone.\",\"nullable\":true,\"type\":\"string\"},\"medicarePartDCatastrophicCoInsuranceValue\":{\"description\":\"Gets or sets Medicare Part D Catastrophic CoInsurance Value.\",\"nullable\":true,\"type\":\"string\"},\"medicarePartDCurrentStage\":{\"description\":\"Gets or sets Medicare Part D Current Stage.\",\"nullable\":true,\"type\":\"string\"},\"medicarePartDGapCoInsuranceValue\":{\"description\":\"Gets or sets Medicare Part D Gap CoInsurance Value.\",\"nullable\":true,\"type\":\"string\"},\"newPlanAvailable\":{\"description\":\"Gets or sets if new plan available.\",\"nullable\":true,\"type\":\"boolean\"},\"newPlanEffectiveDate\":{\"description\":\"Gets or sets the New Plan Effective Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"newPlanSubscriberId\":{\"description\":\"Gets or sets the new plan subscriber id.\",\"nullable\":true,\"type\":\"string\"},\"obtainPriorAuthorizationFax\":{\"description\":\"Gets or sets the Obtain Prior Authorization Fax.\",\"nullable\":true,\"type\":\"string\"},\"obtainPriorAuthorizationOrg\":{\"description\":\"Gets or sets the Obtain Prior Authorization Org.\",\"nullable\":true,\"type\":\"string\"},\"obtainPriorAuthorizationPhone\":{\"description\":\"Gets or sets the Obtain Prior Authorization Phone.\",\"nullable\":true,\"type\":\"string\"},\"obtainPriorAuthorizationRequirements\":{\"description\":\"Gets or sets the Obtain Prior Authorization Requirements.\",\"nullable\":true,\"type\":\"string\"},\"obtainPriorAuthorizationWebsite\":{\"description\":\"Gets or sets the Obtain Prior Authorization Website.\",\"nullable\":true,\"type\":\"string\"},\"obtainTierExceptionPhone\":{\"description\":\"Gets or sets the Obtain Tier Exception Phone.\",\"nullable\":true,\"type\":\"string\"},\"otherInsuranceExists\":{\"description\":\"Gets or sets if Other Insurance Exists .\",\"nullable\":true,\"type\":\"boolean\"},\"payerAgentName\":{\"description\":\"Gets or sets the Payer Agent Name.\",\"nullable\":true,\"type\":\"string\"},\"payerId\":{\"description\":\"Gets or sets the Payer Id.\",\"nullable\":true,\"type\":\"string\"},\"payerPhoneNumber\":{\"description\":\"Sets the PBM Phone Number.\",\"nullable\":true,\"type\":\"string\"},\"payerReferenceId\":{\"description\":\"Gets or sets the Payer Reference ID.\",\"nullable\":true,\"type\":\"string\"},\"pbmName\":{\"description\":\"Sets the name of the PBM payer name.\",\"nullable\":true,\"type\":\"string\"},\"pbmPayorName\":{\"description\":\"Gets or sets the PBM payor name\",\"nullable\":true,\"type\":\"string\"},\"pbmPhoneNumber\":{\"description\":\"Gets or sets the PBM Phone Number\",\"nullable\":true,\"type\":\"string\"},\"pbmResponseMessage\":{\"description\":\"Gets or sets the PBM Response Message\",\"nullable\":true,\"type\":\"string\"},\"pbmSpecialtyPharmacyRequirement\":{\"description\":\"Gets or sets the PBM Specialty Pharmacy Requirement.\",\"nullable\":true,\"type\":\"string\"},\"pcn\":{\"description\":\"Gets or sets the Pcn\",\"nullable\":true,\"type\":\"string\"},\"peerToPeerAvailable\":{\"description\":\"Gets or sets if Peer to Peer Available.\",\"nullable\":true,\"type\":\"boolean\"},\"peerToPeerPhone\":{\"description\":\"Gets or sets the Peer to Peer Phone.\",\"nullable\":true,\"type\":\"string\"},\"peerToPeerSubmissionDeadline\":{\"description\":\"Gets or sets the Peer to Peer Submission Deadline.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"pharmacyNcpdpId\":{\"description\":\"Gets or sets the Pharmacy NCPDP ID\",\"nullable\":true,\"type\":\"string\"},\"pharmacyNpi\":{\"description\":\"Gets or sets the pharmacy NPI\",\"nullable\":true,\"type\":\"string\"},\"planEffectiveDate\":{\"description\":\"Gets or sets the Plan Effective Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"planGroupNo\":{\"description\":\"Gets or sets the Plan Group.\",\"nullable\":true,\"type\":\"string\"},\"planName\":{\"description\":\"Gets or sets the Plan Name.\",\"nullable\":true,\"type\":\"string\"},\"planPriority\":{\"description\":\"Gets or sets the Insurance Priority.\",\"nullable\":true,\"type\":\"string\"},\"planRenewalMonth\":{\"description\":\"Gets or sets the Plan Renewal Month.\",\"nullable\":true,\"type\":\"string\"},\"planRenewalType\":{\"description\":\"Gets or sets the Plan Renewal Type.\",\"nullable\":true,\"type\":\"string\"},\"planTerminationDate\":{\"description\":\"Gets or sets the Plan Termination Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"planType\":{\"description\":\"Gets or sets the Insurance Type.\",\"nullable\":true,\"type\":\"string\"},\"policyNumber\":{\"description\":\"Gets or sets the Card holder Id.\",\"nullable\":true,\"type\":\"string\"},\"policyType\":{\"description\":\"Gets or sets the Policy Type.\",\"nullable\":true,\"type\":\"string\"},\"preferredDrugValue\":{\"description\":\"Gets or sets if there is a Preferred Drug Value.\",\"nullable\":true,\"type\":\"boolean\"},\"priorAuthAppealsContactFax\":{\"description\":\"Gets or sets the Prior Authorization Appeals Contact Fax.\",\"nullable\":true,\"type\":\"string\"},\"priorAuthDenialReason\":{\"description\":\"Gets or sets the Prior Authorization Denial Reason.\",\"nullable\":true,\"type\":\"string\"},\"priorAuthInitiationDate\":{\"description\":\"Gets or sets the Prior Authorization Initiation Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"priorAuthNotificationMethod\":{\"description\":\"Gets or sets the Prior Authorization Notification Method.\",\"nullable\":true,\"type\":\"string\"},\"priorAuthorizationApprovalNumber\":{\"description\":\"Gets or sets the Prior Authorization Approval Number.\",\"nullable\":true,\"type\":\"string\"},\"priorAuthorizationEndDate\":{\"description\":\"Gets or sets the Prior Authorization End Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"priorAuthorizationOnFile\":{\"description\":\"Gets or sets the Prior Authorization On File.\",\"nullable\":true,\"type\":\"boolean\"},\"priorAuthorizationRequired\":{\"description\":\"Gets or sets the prior authorization required\",\"nullable\":true,\"type\":\"boolean\"},\"priorAuthorizationStartDate\":{\"description\":\"Gets or sets the Prior Authorization Start Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"priorAuthorizationStatus\":{\"description\":\"Gets or sets the Prior Authorization Status.\",\"nullable\":true,\"type\":\"string\"},\"priorAuthorizationSubmissionDate\":{\"description\":\"Gets or sets the Prior Authorization Submission Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"priorAuthorizationTurnaroundTime\":{\"description\":\"Gets or sets the Prior Authorization Turnaround Time.\",\"nullable\":true,\"type\":\"string\"},\"productCoverage\":{\"$ref\":\"#/components/schemas/PharmacyBi.PlanProductCoverageModel\"},\"productQuantityLimit\":{\"description\":\"Gets or sets the Quantity Priced.\",\"nullable\":true,\"type\":\"string\"},\"productTier\":{\"description\":\"Gets or sets the Product Tier.\",\"nullable\":true,\"type\":\"string\"},\"programId\":{\"description\":\"Gets or sets the Program Id.\",\"nullable\":true,\"type\":\"string\"},\"quantityPriced\":{\"description\":\"Gets or sets the Quantity Priced\",\"nullable\":true,\"type\":\"string\"},\"quantityUnitDescription\":{\"description\":\"Gets or sets the Quantity Unit Description\",\"nullable\":true,\"type\":\"string\"},\"quantityUnitOfMeasure\":{\"description\":\"Gets or sets the quantity unit of measure\",\"nullable\":true,\"type\":\"string\"},\"rejectionCode\":{\"description\":\"Gets or sets the Rejection Code\",\"nullable\":true,\"type\":\"string\"},\"resubmissionNotificationMethod\":{\"description\":\"Gets or sets the Resubmission Notification Method.\",\"nullable\":true,\"type\":\"string\"},\"resubmissionTurnaroundTime\":{\"description\":\"Gets or sets the Resubmission Turnaround Time.\",\"nullable\":true,\"type\":\"string\"},\"reviewRequired\":{\"description\":\"Gets or sets if review is required.\",\"nullable\":true,\"type\":\"boolean\"},\"rxGroupId\":{\"description\":\"Gets or sets the Rx Group identifier\",\"nullable\":true,\"type\":\"string\"},\"rxGroupNo\":{\"description\":\"Gets or sets the Rx Group identifier.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacy2Fax\":{\"description\":\"Gets or sets Specialty Pharmacy 2 Fax.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacy2Name\":{\"description\":\"Gets or sets Specialty Pharmacy 2 Name.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacy2PhoneNumber\":{\"description\":\"Gets or sets Specialty Pharmacy 2 Phone Number.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacy3Fax\":{\"description\":\"Gets or sets Specialty Pharmacy 3 Fax.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacy3Name\":{\"description\":\"Gets or sets Specialty Pharmacy 3 Name.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacy3PhoneNumber\":{\"description\":\"Gets or sets Specialty Pharmacy 2 Phone Number.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyFax\":{\"description\":\"Gets or sets Specialty Pharmacy Fax.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyName\":{\"description\":\"Gets or sets Specialty Pharmacy Name.\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyPhoneNumber\":{\"description\":\"Gets or sets Specialty Pharmacy Phone Number.\",\"nullable\":true,\"type\":\"string\"},\"stepTherapyRequired\":{\"description\":\"Gets or sets if Step Therapy Required.\",\"nullable\":true,\"type\":\"boolean\"},\"stepTherapyTreatment\":{\"description\":\"Gets or sets Step Therapy Treatment.\",\"nullable\":true,\"type\":\"string\"},\"therapyAvailabilityDate\":{\"description\":\"Gets or sets Therapy Availability Date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"tierExceptionProcess\":{\"description\":\"Gets or sets if there is a Tier Exception Process.\",\"nullable\":true,\"type\":\"boolean\"},\"totalTier\":{\"description\":\"Gets or sets the Total Tier.\",\"nullable\":true,\"type\":\"string\"},\"willCoverIfPrimaryDenies\":{\"description\":\"Gets or sets Will Cover if Primary Denies.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiResponseModel\":{\"description\":\"Pharmacy BI Request Response\",\"properties\":{\"customerId\":{\"description\":\"Gets or sets the CustomerId\",\"nullable\":true,\"type\":\"string\"},\"plans\":{\"description\":\"Gets or sets the plan details\",\"items\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiResponseDetailModel\"},\"nullable\":true,\"type\":\"array\"},\"requestId\":{\"description\":\"Gets or sets the RequestId\",\"format\":\"int64\",\"type\":\"integer\"},\"resultId\":{\"description\":\"Gets or sets the ResultId\",\"format\":\"int64\",\"type\":\"integer\"},\"status\":{\"description\":\"Sets the TransactionStatus if the response uses Status instead.\\r\\nThis is used by the RisRx ProviderCode\",\"type\":\"boolean\"},\"taskCompletedDate\":{\"description\":\"Gets or sets the Task completed date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"taskCreatedDate\":{\"description\":\"Gets or sets the Task created date.\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"},\"taskStatus\":{\"description\":\"Gets or sets the Task Status.\",\"nullable\":true,\"type\":\"string\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyBi.PharmacyBiResponseModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiResponseModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyBi.PlanProductCoverageModel\":{\"description\":\"Plan Product Coverage\",\"properties\":{\"code\":{\"description\":\"Gets or sets the Code\",\"nullable\":true,\"type\":\"string\"},\"covered\":{\"description\":\"Gets or sets if Covered\",\"nullable\":true,\"type\":\"boolean\"},\"mailOrderCoInsurance\":{\"description\":\"Gets or sets the Mail Order CoInsurance\",\"nullable\":true,\"type\":\"string\"},\"mailOrderCovered\":{\"description\":\"Gets or sets if the Mail Order Covered\",\"nullable\":true,\"type\":\"boolean\"},\"mailOrderPharmacyCoPay\":{\"description\":\"Gets or sets the Mail Order Pharmacy CoPay\",\"nullable\":true,\"type\":\"string\"},\"retailPharmacyCoInsurance\":{\"description\":\"Gets or sets the Retail Pharmacy CoInsurance\",\"nullable\":true,\"type\":\"string\"},\"retailPharmacyCoPay\":{\"description\":\"Gets or sets the Retail Pharmacy CoPay\",\"nullable\":true,\"type\":\"string\"},\"retailPharmacyCovered\":{\"description\":\"Gets or sets if the Retail Pharmacy Covered\",\"nullable\":true,\"type\":\"boolean\"},\"specialtyPharmacyCoInsurance\":{\"description\":\"Gets or sets the Specialty Pharmacy CoInsurance\",\"nullable\":true,\"type\":\"string\"},\"specialtyPharmacyCopay\":{\"description\":\"Gets or sets the Specialty Pharmacy Copay\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyBi.RequestSearch.PharmacyBiRequestSearchModel\":{\"description\":\"Pharmacy BI Request\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"PharmacyBi.RequestSearch.PharmacyBiRequestSearchResponseModel\":{\"description\":\"Pharmacy BI Request Search Response\",\"properties\":{\"request\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiModel\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyBi.RequestSearch.PharmacyBiRequestSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/PharmacyBi.RequestSearch.PharmacyBiRequestSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyBi.ResultSearch.PharmacyBiResultSearchModel\":{\"description\":\"Pharmacy BI Request\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"PharmacyBi.ResultSearch.PharmacyBiResultSearchResponseModel\":{\"description\":\"Pharmacy BI Result Search Response\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"result\":{\"$ref\":\"#/components/schemas/PharmacyBi.PharmacyBiResponseModel\"}},\"type\":\"object\"},\"PharmacyBi.ResultSearch.PharmacyBiResultSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/PharmacyBi.ResultSearch.PharmacyBiResultSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyBiRequestSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyBiRequestSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyBiResultSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyBiResultSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyCardFinder-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyCardFinder-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyCardFinder.PharmacyCardFinderAddressModel\":{\"description\":\"Gets or sets the Address.\",\"properties\":{\"addressLine1\":{\"description\":\"Gets or sets the address line1.\",\"nullable\":true,\"type\":\"string\"},\"addressLine2\":{\"description\":\"Gets or sets the  address line2.\",\"nullable\":true,\"type\":\"string\"},\"city\":{\"description\":\"Gets or sets the city.\",\"nullable\":true,\"type\":\"string\"},\"state\":{\"description\":\"Gets or sets the state.\",\"nullable\":true,\"type\":\"string\"},\"zipCode\":{\"description\":\"Gets or sets the Postal code.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyCardFinder.PharmacyCardFinderModel\":{\"description\":\"Pharmacy Card Finder Post Request to EvinceMed\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"daysSupply\":{\"description\":\"Gets or sets the days supply.\",\"nullable\":true,\"type\":\"string\"},\"ndc\":{\"description\":\"Gets or sets the ndc.\",\"nullable\":true,\"type\":\"string\"},\"patient\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.PharmacyCardFinderPatientModel\"},\"pharmacyNcpDpId\":{\"description\":\"Gets or sets the pharmacy ncpdp id.\",\"nullable\":true,\"type\":\"string\"},\"pharmacyNpi\":{\"description\":\"Gets or sets the pharmacy npi.\",\"nullable\":true,\"type\":\"string\"},\"prescriber\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.PharmacyCardFinderPrescriberModel\"},\"quantity\":{\"description\":\"Gets or sets the quantity.\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"PharmacyCardFinder.PharmacyCardFinderPatientModel\":{\"description\":\"Gets or sets the Patient.\",\"properties\":{\"dateOfBirth\":{\"description\":\"Gets or sets the date of birth.\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name.\",\"nullable\":true,\"type\":\"string\"},\"gender\":{\"description\":\"Gets or sets the gender.\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name.\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the phone.\",\"nullable\":true,\"type\":\"string\"},\"zipCode\":{\"description\":\"Gets or sets the zip code.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyCardFinder.PharmacyCardFinderPlanModel\":{\"description\":\"Plan details\",\"properties\":{\"bin\":{\"description\":\"Gets or sets the bin.\",\"nullable\":true,\"type\":\"string\"},\"cardHolderId\":{\"description\":\"Gets or sets the card holder identifier.\",\"nullable\":true,\"type\":\"string\"},\"familyUnitNumber\":{\"description\":\"Gets or sets the family unit number.\",\"nullable\":true,\"type\":\"string\"},\"insurancePriority\":{\"description\":\"Gets or sets the insurance priority.\",\"nullable\":true,\"type\":\"string\"},\"patientDateOfBirth\":{\"description\":\"Gets or sets the patient date of birth.\",\"nullable\":true,\"type\":\"string\"},\"patientFirstName\":{\"description\":\"Gets or sets the first name of the patient.\",\"nullable\":true,\"type\":\"string\"},\"patientLastName\":{\"description\":\"Gets or sets the last name of the patient.\",\"nullable\":true,\"type\":\"string\"},\"patientMiddleName\":{\"description\":\"Gets or sets the name of the patient middle.\",\"nullable\":true,\"type\":\"string\"},\"patientPrefix\":{\"description\":\"Gets or sets the patient prefix.\",\"nullable\":true,\"type\":\"string\"},\"patientSuffix\":{\"description\":\"Gets or sets the patient suffix.\",\"nullable\":true,\"type\":\"string\"},\"patientZipCode\":{\"description\":\"Gets or sets the patient zip code.\",\"nullable\":true,\"type\":\"string\"},\"pbmPayerName\":{\"description\":\"Gets or sets the name of the PBM payer.\",\"nullable\":true,\"type\":\"string\"},\"pbmPhoneNumber\":{\"description\":\"Gets or sets the PBM phone number.\",\"nullable\":true,\"type\":\"string\"},\"pbmResponseMessage\":{\"description\":\"Gets or sets the Plan specific messages.\",\"nullable\":true,\"type\":\"string\"},\"pcn\":{\"description\":\"Gets or sets the PCN.\",\"nullable\":true,\"type\":\"string\"},\"rxGroupId\":{\"description\":\"Gets or sets the rx group identifier.\",\"nullable\":true,\"type\":\"string\"},\"rxGroupName\":{\"description\":\"Gets or sets the name of the rx group.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyCardFinder.PharmacyCardFinderPrescriberModel\":{\"description\":\"Gets or sets the Prescriber.\",\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.PharmacyCardFinderAddressModel\"},\"fax\":{\"description\":\"Gets or sets the prescriber fax.\",\"nullable\":true,\"type\":\"string\"},\"firstName\":{\"description\":\"Gets or sets the first name.\",\"nullable\":true,\"type\":\"string\"},\"lastName\":{\"description\":\"Gets or sets the last name.\",\"nullable\":true,\"type\":\"string\"},\"npi\":{\"description\":\"Gets or sets the npi.\",\"nullable\":true,\"type\":\"string\"},\"phone\":{\"description\":\"Gets or sets the phone.\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PharmacyCardFinder.PharmacyCardFinderResponseModel\":{\"description\":\"Pharmacy Card Finder service response\",\"properties\":{\"plan\":{\"description\":\"Gets or sets the plan.\",\"items\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.PharmacyCardFinderPlanModel\"},\"nullable\":true,\"type\":\"array\"},\"prescriberNpi\":{\"description\":\"Gets or sets the prescriber npi.\",\"nullable\":true,\"type\":\"string\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyCardFinder.PharmacyCardFinderResponseModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.PharmacyCardFinderResponseModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyCardFinder.RequestSearch.PharmacyCardFinderRequestSearchModel\":{\"description\":\"Pharmacy Card Finder Request Search\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"PharmacyCardFinder.RequestSearch.PharmacyCardFinderRequestSearchResponseModel\":{\"description\":\"Pharmacy Card Finder Request Search Response\",\"properties\":{\"request\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.PharmacyCardFinderModel\"},\"transactionCorrelationId\":{\"description\":\"Gets or sets the transaction correlation identifier\",\"format\":\"int64\",\"type\":\"integer\"},\"transactionDateTime\":{\"description\":\"Gets or sets the transaction identifier\",\"format\":\"date-time\",\"type\":\"string\"},\"transactionId\":{\"description\":\"Gets or sets the transaction identifier\",\"nullable\":true,\"type\":\"string\"},\"transactionMessage\":{\"description\":\"Gets or sets the transaction message\",\"nullable\":true,\"type\":\"string\"},\"transactionStatus\":{\"description\":\"Gets or sets the transaction message\",\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyCardFinder.RequestSearch.PharmacyCardFinderRequestSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.RequestSearch.PharmacyCardFinderRequestSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyCardFinder.ResultSearch.PharmacyCardFinderResultSearchModel\":{\"description\":\"Pharmacy Card Finder Result Search\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"isQuickPathCaseId\":{\"description\":\"Gets or sets IsQuickPathCaseId\",\"nullable\":true,\"type\":\"boolean\"},\"searchId\":{\"description\":\"Gets or sets SearchId\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"}},\"type\":\"object\"},\"PharmacyCardFinder.ResultSearch.PharmacyCardFinderResultSearchResponseModel\":{\"description\":\"Pharmacy Card Finder Result Search Response\",\"properties\":{\"clientId1\":{\"description\":\"Client Id 1\",\"nullable\":true,\"type\":\"string\"},\"clientId2\":{\"description\":\"Client Id 2\",\"nullable\":true,\"type\":\"string\"},\"clientId3\":{\"description\":\"Client Id 3\",\"nullable\":true,\"type\":\"string\"},\"clientId4\":{\"description\":\"Client Id 4\",\"nullable\":true,\"type\":\"string\"},\"clientId5\":{\"description\":\"Client Id 5\",\"nullable\":true,\"type\":\"string\"},\"quickPathCaseId\":{\"description\":\"QuickPath Case Id\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"result\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.PharmacyCardFinderResponseModel\"}},\"type\":\"object\"},\"PharmacyCardFinder.ResultSearch.PharmacyCardFinderResultSearchResponseModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/PharmacyCardFinder.ResultSearch.PharmacyCardFinderResultSearchResponseModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"PharmacyCardFinderRequestSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyCardFinderRequestSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyCardFinderResultSearch-programId-PostRequest\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"PharmacyCardFinderResultSearch-programId-PostRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"Program-ExternalSystemCode-ExternalSystemId-GetRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"Program-ExternalSystemCode-ExternalSystemId-GetRequest-1\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"Program-ExternalSystemCode-ExternalSystemId-GetRequest-2\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"Program-Id-GetRequest\":{\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"Program-Id-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"Program-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"Program-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramActivate-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramActivate-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramCreateModel\":{\"description\":\"Program create model\",\"properties\":{\"description\":{\"description\":\"Description\",\"nullable\":true,\"type\":\"string\"},\"externalSystemCode\":{\"description\":\"ExternalSystemCode\",\"nullable\":true,\"type\":\"string\"},\"externalSystemId\":{\"description\":\"ExternalSystemId\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"ProgramName\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ProgramDeactivate-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramDeactivate-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramDetailModel\":{\"description\":\"Program model\",\"properties\":{\"description\":{\"description\":\"Description\",\"nullable\":true,\"type\":\"string\"},\"externalSystemCode\":{\"description\":\"ExternalSystemCode\",\"nullable\":true,\"type\":\"string\"},\"externalSystemId\":{\"description\":\"ExternalSystemId\",\"nullable\":true,\"type\":\"string\"},\"id\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"ProgramName\",\"nullable\":true,\"type\":\"string\"},\"programNdcs\":{\"description\":\"Program Ndcs\",\"items\":{\"$ref\":\"#/components/schemas/ProgramNdcModel\"},\"nullable\":true,\"type\":\"array\"},\"programServices\":{\"description\":\"Program Services\",\"items\":{\"$ref\":\"#/components/schemas/ProgramServiceDetailModel\"},\"nullable\":true,\"type\":\"array\"}},\"type\":\"object\"},\"ProgramDetailModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/ProgramDetailModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ProgramGetRequest\":{\"nullable\":true,\"type\":\"boolean\",\"x-apim-inline\":true},\"ProgramGetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramModel\":{\"description\":\"Program model\",\"properties\":{\"description\":{\"description\":\"Description\",\"nullable\":true,\"type\":\"string\"},\"externalSystemCode\":{\"description\":\"ExternalSystemCode\",\"nullable\":true,\"type\":\"string\"},\"externalSystemId\":{\"description\":\"ExternalSystemId\",\"nullable\":true,\"type\":\"string\"},\"id\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"ProgramName\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ProgramModelIEnumerableResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/ProgramModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ProgramNdc-ProgramId-GetRequest\":{\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdc-ProgramId-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdc-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdc-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdcActivate-Id-PutRequest\":{\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdcActivate-Id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdcCreateModel\":{\"description\":\"Program Ndc create model\",\"properties\":{\"ndcIds\":{\"description\":\"NdcId\",\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"programId\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\"}},\"type\":\"object\"},\"ProgramNdcDeactivate-Id-PutRequest\":{\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdcDeactivate-Id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdcModel\":{\"description\":\"Program Ndc model\",\"properties\":{\"id\":{\"description\":\"Program Ndc Id\",\"format\":\"uuid\",\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"ndcId\":{\"description\":\"NdcId\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ProgramNdcModelListResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/ProgramNdcModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ProgramNdcPostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramNdcUpdateModel\":{\"description\":\"Program Ndc update model\",\"properties\":{\"ndcId\":{\"description\":\"NdcId\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ProgramPostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramService-ProgramId-GetRequest\":{\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramService-ProgramId-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramService-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramService-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramServiceActivate-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramServiceActivate-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramServiceCreateModel\":{\"description\":\"Program Service Create Model\",\"properties\":{\"programId\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\"},\"serviceId\":{\"description\":\"Service Id\",\"format\":\"uuid\",\"type\":\"string\"}},\"type\":\"object\"},\"ProgramServiceDeactivate-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramServiceDeactivate-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramServiceDetailModel\":{\"description\":\"Program Service model\",\"properties\":{\"createdBy\":{\"description\":\"Created By\",\"format\":\"int64\",\"type\":\"integer\"},\"createdOn\":{\"description\":\"Created On\",\"format\":\"date-time\",\"type\":\"string\"},\"id\":{\"description\":\"Program Service Id\",\"format\":\"uuid\",\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"programId\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\"},\"service\":{\"$ref\":\"#/components/schemas/ServiceModel\"},\"serviceId\":{\"description\":\"Service Id\",\"format\":\"uuid\",\"type\":\"string\"},\"updatedBy\":{\"description\":\"Updated By\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"updatedOn\":{\"description\":\"Updated On\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ProgramServiceModel\":{\"description\":\"Program Service Model\",\"properties\":{\"createdBy\":{\"description\":\"Created By\",\"format\":\"int64\",\"type\":\"integer\"},\"createdOn\":{\"description\":\"Created On\",\"format\":\"date-time\",\"type\":\"string\"},\"id\":{\"description\":\"Program Service Id\",\"format\":\"uuid\",\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"programId\":{\"description\":\"Program Id\",\"format\":\"uuid\",\"type\":\"string\"},\"serviceId\":{\"description\":\"Service Id\",\"format\":\"uuid\",\"type\":\"string\"},\"updatedBy\":{\"description\":\"Updated By\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"updatedOn\":{\"description\":\"Updated On\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ProgramServiceModelIEnumerableResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/ProgramServiceModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ProgramServicePostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ProgramUpdateModel\":{\"description\":\"Program update model\",\"properties\":{\"description\":{\"description\":\"Description\",\"nullable\":true,\"type\":\"string\"},\"externalSystemCode\":{\"description\":\"ExternalSystemCode\",\"nullable\":true,\"type\":\"string\"},\"externalSystemId\":{\"description\":\"ExternalSystemId\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"ProgramName\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"PutRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ResponseModel\":{\"properties\":{\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"Service-id-PutRequest\":{\"description\":\"\",\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"Service-id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceActivate-Id-PutRequest\":{\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceActivate-Id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceCreateModel\":{\"description\":\"Service create model\",\"properties\":{\"isAsync\":{\"description\":\"Service is async\",\"type\":\"boolean\"},\"serviceProviderCode\":{\"description\":\"Service provider code\",\"nullable\":true,\"type\":\"string\"},\"serviceTypeCode\":{\"description\":\"Service type code\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceDeactivate-Id-PutRequest\":{\"format\":\"uuid\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceDeactivate-Id-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceGetRequest\":{\"nullable\":true,\"type\":\"boolean\",\"x-apim-inline\":true},\"ServiceGetRequest-1\":{\"nullable\":true,\"type\":\"boolean\",\"x-apim-inline\":true},\"ServiceGetRequest-2\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceModel\":{\"description\":\"Service model\",\"properties\":{\"createdBy\":{\"description\":\"Created By\",\"format\":\"int64\",\"type\":\"integer\"},\"createdOn\":{\"description\":\"Created On\",\"format\":\"date-time\",\"type\":\"string\"},\"id\":{\"description\":\"Service Id\",\"format\":\"uuid\",\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"isAsync\":{\"description\":\"Service is async\",\"type\":\"boolean\"},\"serviceProviderCode\":{\"description\":\"Service provider code\",\"nullable\":true,\"type\":\"string\"},\"serviceTypeCode\":{\"description\":\"Service type code\",\"nullable\":true,\"type\":\"string\"},\"updatedBy\":{\"description\":\"Updated By\",\"format\":\"int64\",\"nullable\":true,\"type\":\"integer\"},\"updatedOn\":{\"description\":\"Updated On\",\"format\":\"date-time\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceModelIEnumerableResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/ServiceModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ServicePostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProvider-Code-GetRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProvider-Code-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProvider-code-PutRequest\":{\"description\":\"\",\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProvider-code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProviderActivate-Code-PutRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProviderActivate-Code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProviderCreateModel\":{\"description\":\"Service provider create model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceProviderDeactivate-Code-PutRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProviderDeactivate-Code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProviderDetailsModel\":{\"description\":\"Service provider details model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"},\"serviceTypes\":{\"description\":\"Service types that the service provider provide\",\"items\":{\"$ref\":\"#/components/schemas/ServiceProviderDetailsModel.ServiceType\"},\"nullable\":true,\"type\":\"array\"}},\"type\":\"object\"},\"ServiceProviderDetailsModel.ServiceType\":{\"description\":\"Service type\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"},\"serviceId\":{\"description\":\"Service ID\",\"format\":\"uuid\",\"type\":\"string\"}},\"type\":\"object\"},\"ServiceProviderDetailsModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/ServiceProviderDetailsModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ServiceProviderGetRequest\":{\"nullable\":true,\"type\":\"boolean\",\"x-apim-inline\":true},\"ServiceProviderGetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProviderModel\":{\"description\":\"Service provider model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceProviderModelIEnumerableResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/ServiceProviderModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ServiceProviderPostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceProviderUpdateModel\":{\"description\":\"Service provider update model\",\"properties\":{\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceStatusModel\":{\"properties\":{\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"properties\":{\"additionalProperties\":{\"type\":\"string\"},\"nullable\":true,\"readOnly\":true,\"type\":\"object\"},\"success\":{\"type\":\"boolean\"},\"timestampLocal\":{\"format\":\"date-time\",\"readOnly\":true,\"type\":\"string\"},\"timestampUtc\":{\"format\":\"date-time\",\"readOnly\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceType-Code-GetRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceType-Code-GetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceType-code-PutRequest\":{\"description\":\"\",\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceType-code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceTypeActivate-Code-PutRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceTypeActivate-Code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceTypeCreateModel\":{\"description\":\"Service type create model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceTypeDeactivate-Code-PutRequest\":{\"nullable\":true,\"type\":\"string\",\"x-apim-inline\":true},\"ServiceTypeDeactivate-Code-PutRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceTypeDetailsModel\":{\"description\":\"Service type details model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"},\"serviceProviders\":{\"description\":\"Service providers that provide the service type\",\"items\":{\"$ref\":\"#/components/schemas/ServiceTypeDetailsModel.ServiceProvider\"},\"nullable\":true,\"type\":\"array\"}},\"type\":\"object\"},\"ServiceTypeDetailsModel.ServiceProvider\":{\"description\":\"Service provider\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"},\"serviceId\":{\"description\":\"Service ID\",\"format\":\"uuid\",\"type\":\"string\"}},\"type\":\"object\"},\"ServiceTypeDetailsModelResponseModel\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/ServiceTypeDetailsModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ServiceTypeGetRequest\":{\"nullable\":true,\"type\":\"boolean\",\"x-apim-inline\":true},\"ServiceTypeGetRequest-1\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceTypeModel\":{\"description\":\"Service type model\",\"properties\":{\"code\":{\"description\":\"Code\",\"nullable\":true,\"type\":\"string\"},\"isActive\":{\"description\":\"Is active\",\"type\":\"boolean\"},\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceTypeModelIEnumerableResponseModel\":{\"properties\":{\"data\":{\"items\":{\"$ref\":\"#/components/schemas/ServiceTypeModel\"},\"nullable\":true,\"type\":\"array\"},\"messages\":{\"items\":{\"type\":\"string\"},\"nullable\":true,\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"ServiceTypePostRequest\":{\"default\":\"TebAFXWZJaChmrxplZu0Ug~~\",\"type\":\"string\",\"x-apim-inline\":true},\"ServiceTypeUpdateModel\":{\"description\":\"Service type update model\",\"properties\":{\"name\":{\"description\":\"Name\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"},\"ServiceUpdateModel\":{\"description\":\"Service update model\",\"properties\":{\"isAsync\":{\"description\":\"Service is async\",\"type\":\"boolean\"},\"serviceProviderCode\":{\"description\":\"Service provider code\",\"nullable\":true,\"type\":\"string\"},\"serviceTypeCode\":{\"description\":\"Service type code\",\"nullable\":true,\"type\":\"string\"}},\"type\":\"object\"}}}"
#   content_type        = "application/vnd.oai.openapi.components+json"
#   resource_group_name = data.azurerm_resource_group.rg_deployment.name
#   schema_id           = "6387c04901234e0e6c2b5569"
#   depends_on = [
#     azurerm_api_management_api.api_eservices_orchestrator,
#   ]
# }
