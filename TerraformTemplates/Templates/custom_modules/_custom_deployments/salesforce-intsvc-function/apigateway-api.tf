resource "azapi_resource" "auth0-token-cache-fragment" {
  type      = "Microsoft.ApiManagement/service/policyFragments@2021-12-01-preview"
  name      = "auth0-token-cache"
  parent_id = data.azurerm_api_management.apim.id

  body = jsonencode({
    properties = {
      description = "Request a token using the normal JWT pattern (in this case powered by auth0)"
      format      = "rawxml"
      value       = <<XML
<fragment>
	<choose>
		<when condition="@(!context.Variables.ContainsKey("authorizationServer"))">
			<set-variable name="authorizationServer" value="{{auth0AuthorizationServer}}" />
		</when>
	</choose>
	<choose>
		<when condition="@(!context.Variables.ContainsKey("clientId"))">
			<set-variable name="clientId" value="{{auth0DefaultClientId}}" />
		</when>
	</choose>
	<choose>
		<when condition="@(!context.Variables.ContainsKey("clientSecret"))">
			<set-variable name="clientSecret" value="{{auth0DefaultClientSecret}}" />
		</when>
	</choose>
	<choose>
		<when condition="@(!context.Variables.ContainsKey("tokenCacheKey"))">
			<set-variable name="tokenCacheKey" value="@(context.Api.Name.Replace(" ", "") + "Token" +(string)context.Variables["clientId"])" />
		</when>
	</choose>
	<cache-lookup-value key="@((string)context.Variables["tokenCacheKey"])" variable-name="bearerToken" />
	<choose>
		<when condition="@(!context.Variables.ContainsKey("bearerToken"))">
			<send-request ignore-error="true" timeout="20" response-variable-name="bearerTokenResponse" mode="new">
				<set-url>{{auth0AuthorizationServer}}</set-url>
				<set-method>POST</set-method>
				<set-header name="Content-Type" exists-action="override">
					<value>application/x-www-form-urlencoded</value>
				</set-header>
				<set-body>@{
					return string.Format(
						"audience={0}&client_id={1}&client_secret={2}&grant_type=client_credentials",
						(string)context.Variables["audienceId"],
						(string)context.Variables["clientId"],
						(string)context.Variables["clientSecret"]
					);
				}</set-body>
			</send-request>
			<set-variable name="auth0_request_response" value="@((JObject)((IResponse)context.Variables["bearerTokenResponse"]).Body.As<JObject>())" />
			<set-variable name="bearerToken" value="@((string)((JObject)context.Variables["auth0_request_response"])["access_token"])" />
			<set-variable name="_expiresIn" value="@(((JObject)context.Variables["auth0_request_response"])["expires_in"].Value<int>())" />
			<!-- Store result in cache -->
			<cache-store-value key="@((string)context.Variables["tokenCacheKey"])" value="@((string)context.Variables["bearerToken"])" duration="@(((int)context.Variables["_expiresIn"]) - 60)" />
		</when>
	</choose>
	<set-header name="Authorization" exists-action="override">
		<value>@("Bearer " + (string)context.Variables["bearerToken"])</value>
	</set-header>
	<!--  Don't expose APIM subscription key to the backend. -->
	<set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
</fragment>
      XML
    }
  })

  depends_on = [
    azurerm_api_management_named_value.auth0DefaultClientId,
    azurerm_api_management_named_value.auth0AuthorizationServer,
    azurerm_api_management_named_value.auth0DefaultClientSecret,
  ]
}

resource "azurerm_api_management_api_operation_policy" "api_policy_ClientEnrollmentCreateEnrollment" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  operation_id        = "ClientEnrollmentCreateEnrollment"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="/edge/enrollment/v1/basic/enrollment/createEnrollment?x-tenant-id={tenantId}&amp;x-program-id={programId}" />
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
    azurerm_api_management_api_operation.api_operation_ClientEnrollmentCreateEnrollment,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_ClientEnrollmentCreateEnrollment" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  display_name        = "ClientEnrollmentCreateEnrollment"
  method              = "POST"
  operation_id        = "ClientEnrollmentCreateEnrollment"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/{tenantId}/{programId}/createEnrollment"
  response {
    description = "default response"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "BasicEnrollmentResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"accountId\":0,\"claimEligibilityDate\":\"string\",\"endDate\":\"string\",\"enrollmentId\":0,\"enrollmentStatus\":\"string\",\"isOptedIn\":true,\"maxBenefitAmount\":0,\"medicalMemberNumber\":\"string\",\"medicalMemberNumberDetails\":{\"bin\":\"string\",\"groupNumber\":\"string\",\"pcn\":\"string\"},\"messages\":[\"string\"],\"pharamacyMemberNumber\":\"string\",\"pharmacyMemberNumberDetails\":{\"bin\":\"string\",\"groupNumber\":\"string\",\"pcn\":\"string\"},\"queuedProcessingDate\":\"string\",\"reenrollmentEligibilityDate\":\"string\",\"startDate\":\"string\",\"untrackedBenefit\":true}"
    #   }
    # }
  }
  response {
    description = "Cannot Process Request"
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Unauthorized / No Bearer Token Found"
    status_code = 401
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Forbidden / Feature Missing"
    status_code = 403
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Precondition Failed / Session Missing"
    status_code = 412
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Internal Server Error"
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  template_parameter {
    name     = "tenantId"
    required = true
    type     = "number"
  }
  template_parameter {
    name     = "programId"
    required = true
    type     = "number"
  }


  depends_on = [
    azurerm_api_management_api.api_trialcard_api_gateway,
  ]
}
resource "azurerm_api_management_api" "api_trialcard_api_gateway" {
  api_management_name   = data.azurerm_api_management.apim.name
  display_name          = "trialcard-api-gateway"
  name                  = "trialcard-api-gateway"
  resource_group_name   = data.azurerm_resource_group.rg_deployment.name
  revision              = "1"
  subscription_required = false
  protocols             = ["https"]
  path                  = "apigateway"

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_ClientEnrollmentCreateEnrollment" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_ClientEnrollmentCreateEnrollment.id
#   display_name     = "Enrollment"
#   name             = "Enrollment"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_ClientEnrollmentCreateEnrollment,
#   ]
# }
resource "azurerm_api_management_api_operation" "api_operation_ClientEnrollmentDeactivateEnrollment" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  display_name        = "ClientEnrollmentDeactivateEnrollment"
  method              = "POST"
  operation_id        = "ClientEnrollmentDeactivateEnrollment"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/{tenantId}/{programId}/deactivateEnrollment"
  response {
    description = "default response"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "BasicEnrollmentDeactivateResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Cannot Process Request"
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Unauthorized / No Bearer Token Found"
    status_code = 401
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Forbidden / Feature Missing"
    status_code = 403
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Precondition Failed / Session Missing"
    status_code = 412
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Internal Server Error"
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  template_parameter {
    name     = "tenantId"
    required = true
    type     = "number"
  }
  template_parameter {
    name     = "programId"
    required = true
    type     = "number"
  }

  depends_on = [
    azurerm_api_management_api.api_trialcard_api_gateway,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_ClientEnrollmentDeactivateEnrollment" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  operation_id        = "ClientEnrollmentDeactivateEnrollment"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="/edge/enrollment/v1/basic/enrollment/deactivateEnrollment??x-tenant-id={tenantId}&amp;x-program-id={programId}" />
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
    azurerm_api_management_api_operation.api_operation_ClientEnrollmentDeactivateEnrollment,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_ClientEnrollmentDeactivateEnrollment" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_ClientEnrollmentDeactivateEnrollment.id
#   display_name     = "Enrollment"
#   name             = "Enrollment"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_ClientEnrollmentDeactivateEnrollment,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_ClientEnrollmentGetEnrollmentByAccountId" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  operation_id        = "ClientEnrollmentGetEnrollmentByAccountId"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="/edge/enrollment/v1/basic/enrollment/getEnrollmentByAccountId/{accountId}?x-tenant-id={tenantId}&amp;x-program-id={programId}" />
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
    azurerm_api_management_api_operation.api_operation_ClientEnrollmentGetEnrollmentByAccountId,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_ClientEnrollmentGetEnrollmentByAccountId" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  display_name        = "ClientEnrollmentGetEnrollmentByAccountId"
  method              = "GET"
  operation_id        = "ClientEnrollmentGetEnrollmentByAccountId"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/{tenantId}/{programId}/getEnrollmentByAccountId/{accountId}"
  response {
    description = "default response"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "BasicEnrollmentResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"accountId\":0,\"claimEligibilityDate\":\"string\",\"endDate\":\"string\",\"enrollmentId\":0,\"enrollmentStatus\":\"string\",\"isOptedIn\":true,\"maxBenefitAmount\":0,\"medicalMemberNumber\":\"string\",\"medicalMemberNumberDetails\":{\"bin\":\"string\",\"groupNumber\":\"string\",\"pcn\":\"string\"},\"messages\":[\"string\"],\"pharamacyMemberNumber\":\"string\",\"pharmacyMemberNumberDetails\":{\"bin\":\"string\",\"groupNumber\":\"string\",\"pcn\":\"string\"},\"queuedProcessingDate\":\"string\",\"reenrollmentEligibilityDate\":\"string\",\"startDate\":\"string\",\"untrackedBenefit\":true}"
    #   }
    # }
  }
  response {
    description = "Cannot Process Request"
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Unauthorized / No Bearer Token Found"
    status_code = 401
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Forbidden / Feature Missing"
    status_code = 403
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Precondition Failed / Session Missing"
    status_code = 412
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Internal Server Error"
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  template_parameter {
    name     = "tenantId"
    required = true
    type     = "number"
  }
  template_parameter {
    name     = "programId"
    required = true
    type     = "number"
  }
  template_parameter {
    name     = "accountId"
    required = true
    type     = "number"
  }

  depends_on = [
    azurerm_api_management_api.api_trialcard_api_gateway,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_ClientEnrollmentGetEnrollmentByAccountId" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_ClientEnrollmentGetEnrollmentByAccountId.id
#   display_name     = "Enrollment"
#   name             = "Enrollment"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_ClientEnrollmentGetEnrollmentByAccountId,
#   ]
# }
resource "azurerm_api_management_api_operation" "api_operation_ClientEnrollmentGetEnrollmentByExternalId" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  display_name        = "ClientEnrollmentGetEnrollmentByExternalId"
  method              = "POST"
  operation_id        = "ClientEnrollmentGetEnrollmentByExternalId"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/{tenantId}/{programId}/getEnrollmentByExternalId"
  response {
    description = "default response"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "ClientEnrollmentControllerGetEnrollmentByExternalIdResponse"
    #   example {
    #     name  = "default"
    #     value = "[{\"accountId\":0,\"benefitPeriodId\":0,\"bestEnrollmentType\":\"Active\",\"caseId\":0,\"caseInitiatorId\":0,\"caseSourceId\":0,\"caseStatusCode\":\"string\",\"caseSubStatusCode\":\"string\",\"claimEligibilityDate\":\"string\",\"conditionTypeCodeList\":[\"string\"],\"createDate\":\"string\",\"endDate\":\"string\",\"enrollmentFlags\":{\"isActiveEnrollmentForCurrentDate\":true,\"lastOneOrMoreDays\":true},\"householdSize\":0,\"isOpen\":true,\"isOptedIn\":true,\"isQueued\":true,\"isTest\":true,\"lastOneOrMoreDays\":true,\"linkedEntities\":{\"documents\":[{\"comment\":\"string\",\"documentId\":0}],\"notes\":[0],\"payors\":[{\"caseRelations\":[{\"coverageOrder\":0,\"isPrimary\":true,\"partyRoleId\":0}],\"roleType\":0}],\"pharmacies\":[{\"isPrimary\":true,\"partyRoleId\":0}],\"prescribers\":[{\"isPrimary\":true,\"partyRoleId\":0}],\"prescriptions\":[{\"documentId\":0,\"prescriberId\":0,\"prescriptionId\":0}],\"sites\":[{\"isPrimary\":true,\"partyRoleId\":0}],\"tasks\":[0]},\"maxBenefitAmount\":0,\"memberNumbers\":[{\"number\":\"string\",\"offerTypeId\":0,\"originalPaymentCode\":\"string\",\"paymentMethod\":0,\"statusCode\":\"string\",\"tcProgramId\":0,\"type\":0}],\"paymentType\":0,\"startDate\":\"string\",\"status\":{\"conditions\":[{\"caseId\":0,\"categoryCode\":\"string\",\"code\":\"string\",\"description\":\"string\"}],\"status\":0},\"untrackedBenefit\":true,\"updateCaseIds\":[0]}]"
    #   }
    # }
  }
  response {
    description = "Cannot Process Request"
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Unauthorized / No Bearer Token Found"
    status_code = 401
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Forbidden / Feature Missing"
    status_code = 403
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Precondition Failed / Session Missing"
    status_code = 412
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Internal Server Error"
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  template_parameter {
    name     = "tenantId"
    required = true
    type     = "number"
  }
  template_parameter {
    name     = "programId"
    required = true
    type     = "number"
  }

  depends_on = [
    azurerm_api_management_api.api_trialcard_api_gateway,
  ]
}
resource "azurerm_api_management_api_operation_policy" "api_policy_ClientEnrollmentGetEnrollmentByExternalId" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  operation_id        = "ClientEnrollmentGetEnrollmentByExternalId"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="/edge/enrollment/v1/basic/enrollment/getEnrollmentByExternalId?x-tenant-id={tenantId}&amp;x-program-id={programId}" />
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
    azurerm_api_management_api_operation.api_operation_ClientEnrollmentGetEnrollmentByExternalId,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_ClientEnrollmentGetEnrollmentByExternalId" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_ClientEnrollmentGetEnrollmentByExternalId.id
#   display_name     = "Enrollment"
#   name             = "Enrollment"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_ClientEnrollmentGetEnrollmentByExternalId,
#   ]
# }
resource "azurerm_api_management_api_operation_policy" "api_policy_ClientEnrollmentUpdateEnrollment" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  operation_id        = "ClientEnrollmentUpdateEnrollment"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <base />
        <rewrite-uri template="/edge/enrollment/v1/basic/enrollment/updateEnrollment/{accountId}?x-tenant-id={tenantId}&amp;x-program-id={programId}" />
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
    azurerm_api_management_api_operation.api_operation_ClientEnrollmentUpdateEnrollment,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_ClientEnrollmentUpdateEnrollment" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  display_name        = "ClientEnrollmentUpdateEnrollment"
  method              = "POST"
  operation_id        = "ClientEnrollmentUpdateEnrollment"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/{tenantId}/{programId}/updateEnrollment/{accountId}"
  response {
    description = "default response"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "BasicEnrollmentResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"accountId\":0,\"claimEligibilityDate\":\"string\",\"endDate\":\"string\",\"enrollmentId\":0,\"enrollmentStatus\":\"string\",\"isOptedIn\":true,\"maxBenefitAmount\":0,\"medicalMemberNumber\":\"string\",\"medicalMemberNumberDetails\":{\"bin\":\"string\",\"groupNumber\":\"string\",\"pcn\":\"string\"},\"messages\":[\"string\"],\"pharamacyMemberNumber\":\"string\",\"pharmacyMemberNumberDetails\":{\"bin\":\"string\",\"groupNumber\":\"string\",\"pcn\":\"string\"},\"queuedProcessingDate\":\"string\",\"reenrollmentEligibilityDate\":\"string\",\"startDate\":\"string\",\"untrackedBenefit\":true}"
    #   }
    # }
  }
  response {
    description = "Cannot Process Request"
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Unauthorized / No Bearer Token Found"
    status_code = 401
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Forbidden / Feature Missing"
    status_code = 403
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Precondition Failed / Session Missing"
    status_code = 412
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  response {
    description = "Internal Server Error"
    status_code = 500
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "6398d93f01234e1780d58aef"
    #   type_name    = "GatewayError"
    #   example {
    #     name  = "default"
    #     value = "{\"messages\":[\"string\"],\"success\":true}"
    #   }
    # }
  }
  template_parameter {
    name     = "tenantId"
    required = true
    type     = "number"
  }
  template_parameter {
    name     = "programId"
    required = true
    type     = "number"
  }
  template_parameter {
    name      = "accountId"
    required  = true
    #schema_id = "6398d93f01234e1780d58aef"
    type      = "number"
    type_name = "EdgeEnrollmentV1BasicEnrollmentUpdateEnrollment-accountId-OperationsRequest"
  }

  depends_on = [
    azurerm_api_management_api.api_trialcard_api_gateway,
  ]
}
# resource "azurerm_api_management_api_operation_tag" "api_operation_tag_ClientEnrollmentUpdateEnrollment" {
#   api_operation_id = azurerm_api_management_api_operation.api_operation_ClientEnrollmentUpdateEnrollment.id
#   display_name     = "Enrollment"
#   name             = "Enrollment"
#   depends_on = [
#     azurerm_api_management_api_operation.api_operation_ClientEnrollmentUpdateEnrollment,
#   ]
# }
resource "azurerm_api_management_api_policy" "api_management_policy_trialcard-api-gateway" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "trialcard-api-gateway"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <set-backend-service backend-id="apigateway" />
        <base />
        <set-variable name="audienceId" value="{{enrollment-audience}}" />
        <include-fragment fragment-id="auth0-token-cache" />
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
    azurerm_api_management_api.api_trialcard_api_gateway,
    azapi_resource.auth0-token-cache-fragment
  ]
}
# resource "azurerm_api_management_api_schema" "api_schema_6398d93f01234e1780d58aef" {
#   api_management_name = data.azurerm_api_management.apim.name
#   api_name            = "trialcard-api-gateway"
#   components          = "{\"schemas\":{\"AccountExternalIdType\":{\"enum\":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],\"type\":\"number\",\"x-enum-def\":[{\"name\":\"UNKN\",\"value\":0},{\"name\":\"UBCHUBID\",\"value\":1},{\"name\":\"TrialCardHubId\",\"value\":2},{\"name\":\"MemberNumber\",\"value\":3},{\"name\":\"ADLDS\",\"value\":4},{\"name\":\"MedMemberID\",\"value\":5},{\"name\":\"PharMemberID\",\"value\":6},{\"name\":\"THIRDPARTYID\",\"value\":7},{\"name\":\"ARXRxId\",\"value\":8},{\"name\":\"CarePathId\",\"value\":9},{\"name\":\"VMIPatientId\",\"value\":10},{\"name\":\"PorticoPortalId\",\"value\":11},{\"name\":\"SiteAccountId\",\"value\":12},{\"name\":\"PatientMckId\",\"value\":13},{\"name\":\"RemsId\",\"value\":14},{\"name\":\"MangoActivationId\",\"value\":15},{\"name\":\"PatientPartnerId\",\"value\":16},{\"name\":\"PartnerPatientId\",\"value\":17},{\"name\":\"SunovionID\",\"value\":18},{\"name\":\"PharmaCordPatientId\",\"value\":19},{\"name\":\"IBondId\",\"value\":20},{\"name\":\"IBondEnrollmentId\",\"value\":21},{\"name\":\"InfinitusId\",\"value\":22},{\"name\":\"EvinceMedId\",\"value\":23}],\"x-enum-schema\":\"AccountExternalIdType\",\"x-enum-varnames\":[\"UNKN\",\"UBCHUBID\",\"TrialCardHubId\",\"MemberNumber\",\"ADLDS\",\"MedMemberID\",\"PharMemberID\",\"THIRDPARTYID\",\"ARXRxId\",\"CarePathId\",\"VMIPatientId\",\"PorticoPortalId\",\"SiteAccountId\",\"PatientMckId\",\"RemsId\",\"MangoActivationId\",\"PatientPartnerId\",\"PartnerPatientId\",\"SunovionID\",\"PharmaCordPatientId\",\"IBondId\",\"IBondEnrollmentId\",\"InfinitusId\",\"EvinceMedId\"]},\"BasicEnrollmentAddress\":{\"properties\":{\"addressOne\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"addressTwo\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"city\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"state\":{\"maxLength\":2,\"minLength\":2,\"type\":\"string\"},\"zip\":{\"maxLength\":5,\"minLength\":5,\"type\":\"string\"}},\"required\":[\"city\",\"state\"],\"type\":\"object\"},\"BasicEnrollmentContact\":{\"properties\":{\"altPhoneNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"firstName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"lastName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"phoneNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"}},\"type\":\"object\"},\"BasicEnrollmentDeactivateRequest\":{\"properties\":{\"effectiveDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"enrollmentId\":{\"type\":\"number\"}},\"required\":[\"enrollmentId\",\"effectiveDate\"],\"type\":\"object\"},\"BasicEnrollmentDeactivateResponse\":{\"properties\":{\"messages\":{\"items\":{\"type\":\"string\"},\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"required\":[\"success\"],\"type\":\"object\"},\"BasicEnrollmentEthnicity\":{\"enum\":[\"H\",\"N\",\"X\"],\"type\":\"string\",\"x-enum-def\":[{\"name\":\"Hispanic\",\"value\":\"H\"},{\"name\":\"NotHispanic\",\"value\":\"N\"},{\"name\":\"NoAnswer\",\"value\":\"X\"}],\"x-enum-schema\":\"BasicEnrollmentEthnicity\",\"x-enum-varnames\":[\"Hispanic\",\"NotHispanic\",\"NoAnswer\"]},\"BasicEnrollmentGender\":{\"enum\":[\"female\",\"male\",\"unknown\",\"indeterminate\",\"transgender\",\"prefernottoanswer\"],\"type\":\"string\",\"x-enum-def\":[{\"name\":\"female\",\"value\":\"female\"},{\"name\":\"male\",\"value\":\"male\"},{\"name\":\"unknown\",\"value\":\"unknown\"},{\"name\":\"indeterminate\",\"value\":\"indeterminate\"},{\"name\":\"transgender\",\"value\":\"transgender\"},{\"name\":\"prefernottoanswer\",\"value\":\"prefernottoanswer\"}],\"x-enum-schema\":\"BasicEnrollmentGender\",\"x-enum-varnames\":[\"female\",\"male\",\"unknown\",\"indeterminate\",\"transgender\",\"prefernottoanswer\"]},\"BasicEnrollmentMedicalPayor\":{\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/BasicEnrollmentAddress\"},\"faxNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"faxNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"groupNumber\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"isPlaceholder\":{\"type\":\"boolean\"},\"name\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"phoneNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"phoneNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"planEffectiveDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"planExpirationDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"planTerminationDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"policyHolderFirstName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"policyHolderLastName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"policyName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"policyNumber\":{\"maxLength\":80,\"minLength\":0,\"type\":\"string\"},\"relationshipToPatient\":{\"$ref\":\"#/components/schemas/RoleType\"}},\"type\":\"object\"},\"BasicEnrollmentMemberNumberDetails\":{\"properties\":{\"bin\":{\"type\":\"string\"},\"groupNumber\":{\"type\":\"string\"},\"pcn\":{\"type\":\"string\"}},\"type\":\"object\"},\"BasicEnrollmentPatient\":{\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/BasicEnrollmentAddress\"},\"cellPhone\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"cellVoicemail\":{\"type\":\"boolean\"},\"contact\":{\"$ref\":\"#/components/schemas/BasicEnrollmentContact\"},\"dateOfBirth\":{\"format\":\"date-time\",\"type\":\"string\"},\"emailAddress\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"emailOptIn\":{\"type\":\"boolean\"},\"emailPreferred\":{\"type\":\"boolean\"},\"ethnicity\":{\"$ref\":\"#/components/schemas/BasicEnrollmentEthnicity\"},\"firstName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"gender\":{\"$ref\":\"#/components/schemas/BasicEnrollmentGender\"},\"homePhone\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"homeVoicemail\":{\"type\":\"boolean\"},\"lastName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"mailOptIn\":{\"type\":\"boolean\"},\"mailPreferred\":{\"type\":\"boolean\"},\"medicalMemberNumber\":{\"maxLength\":9,\"minLength\":0,\"type\":\"string\"},\"middleName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"pharmacyMemberNumber\":{\"maxLength\":11,\"minLength\":0,\"type\":\"string\"},\"phoneOptIn\":{\"type\":\"boolean\"},\"phonePreferred\":{\"type\":\"boolean\"},\"race\":{\"$ref\":\"#/components/schemas/BasicEnrollmentRace\"},\"ssn\":{\"maxLength\":9,\"minLength\":0,\"type\":\"string\"},\"suffix\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"textOptIn\":{\"type\":\"boolean\"},\"textPreferred\":{\"type\":\"boolean\"},\"thirdPartyId\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"workPhone\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"workPhoneExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"workVoicemail\":{\"type\":\"boolean\"}},\"required\":[\"firstName\",\"lastName\",\"dateOfBirth\",\"address\"],\"type\":\"object\"},\"BasicEnrollmentPaymentType\":{\"enum\":[\"debitcard\",\"check\",\"virtualdebitcard\",\"thirdpartyadjudication\",\"sitecheckforpatient\",\"sitecheckforsite\",\"efttosite\",\"copaycard\"],\"type\":\"string\",\"x-enum-def\":[{\"name\":\"debitcard\",\"value\":\"debitcard\"},{\"name\":\"check\",\"value\":\"check\"},{\"name\":\"virtualdebitcard\",\"value\":\"virtualdebitcard\"},{\"name\":\"thirdpartyadjudication\",\"value\":\"thirdpartyadjudication\"},{\"name\":\"sitecheckforpatient\",\"value\":\"sitecheckforpatient\"},{\"name\":\"sitecheckforsite\",\"value\":\"sitecheckforsite\"},{\"name\":\"efttosite\",\"value\":\"efttosite\"},{\"name\":\"copaycard\",\"value\":\"copaycard\"}],\"x-enum-schema\":\"BasicEnrollmentPaymentType\",\"x-enum-varnames\":[\"debitcard\",\"check\",\"virtualdebitcard\",\"thirdpartyadjudication\",\"sitecheckforpatient\",\"sitecheckforsite\",\"efttosite\",\"copaycard\"]},\"BasicEnrollmentPharmacy\":{\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/BasicEnrollmentAddress\"},\"faxNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"faxNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"nabp\":{\"maxLength\":20,\"minLength\":0,\"type\":\"string\"},\"name\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"npi\":{\"maxLength\":20,\"minLength\":0,\"type\":\"string\"},\"phoneNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"phoneNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"}},\"type\":\"object\"},\"BasicEnrollmentPharmacyPayor\":{\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/BasicEnrollmentAddress\"},\"bin\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"faxNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"faxNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"groupNumber\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"isPlaceholder\":{\"type\":\"boolean\"},\"name\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"pcn\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"phoneNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"phoneNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"planEffectiveDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"planExpirationDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"planTerminationDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"policyHolderFirstName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"policyHolderLastName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"policyName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"policyNumber\":{\"maxLength\":80,\"minLength\":0,\"type\":\"string\"},\"relationshipToPatient\":{\"$ref\":\"#/components/schemas/RoleType\"}},\"type\":\"object\"},\"BasicEnrollmentPrescriber\":{\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/BasicEnrollmentAddress\"},\"deaNumber\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"faxNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"faxNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"firstName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"lastName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"middleName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"npi\":{\"maxLength\":20,\"minLength\":0,\"type\":\"string\"},\"phoneNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"phoneNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"ptan\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"stateLicenseId\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"suffix\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"taxId\":{\"maxLength\":20,\"minLength\":0,\"type\":\"string\"}},\"type\":\"object\"},\"BasicEnrollmentPrescription\":{\"properties\":{\"daySupply\":{\"type\":\"number\"},\"directions\":{\"maxLength\":8000,\"minLength\":0,\"type\":\"string\"},\"ndc\":{\"maxLength\":1024,\"minLength\":0,\"type\":\"string\"},\"quantity\":{\"type\":\"number\"},\"refills\":{\"type\":\"number\"},\"writtenOn\":{\"format\":\"date-time\",\"type\":\"string\"}},\"type\":\"object\"},\"BasicEnrollmentRace\":{\"enum\":[\"Asian\",\"Black\",\"Multiple\",\"NativeAmerican\",\"NativePacificIsles\",\"Unknown\",\"White\"],\"type\":\"string\",\"x-enum-def\":[{\"name\":\"Asian\",\"value\":\"Asian\"},{\"name\":\"Black\",\"value\":\"Black\"},{\"name\":\"Multiple\",\"value\":\"Multiple\"},{\"name\":\"NativeAmerican\",\"value\":\"NativeAmerican\"},{\"name\":\"NativePacificIsles\",\"value\":\"NativePacificIsles\"},{\"name\":\"Unknown\",\"value\":\"Unknown\"},{\"name\":\"White\",\"value\":\"White\"}],\"x-enum-schema\":\"BasicEnrollmentRace\",\"x-enum-varnames\":[\"Asian\",\"Black\",\"Multiple\",\"NativeAmerican\",\"NativePacificIsles\",\"Unknown\",\"White\"]},\"BasicEnrollmentRequest\":{\"properties\":{\"caseInitiator\":{\"$ref\":\"#/components/schemas/EnrollPatientCaseInitiator\"},\"caseSource\":{\"$ref\":\"#/components/schemas/EnrollPatientCaseSource\"},\"diagnosisCodes\":{\"items\":{\"maxLength\":20,\"minLength\":0,\"type\":\"string\"},\"type\":\"array\"},\"enrollmentPaymentType\":{\"$ref\":\"#/components/schemas/BasicEnrollmentPaymentType\"},\"medicalPayors\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentMedicalPayor\"},\"type\":\"array\"},\"patient\":{\"$ref\":\"#/components/schemas/BasicEnrollmentPatient\"},\"pharmacies\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentPharmacy\"},\"type\":\"array\"},\"pharmacyPayors\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentPharmacyPayor\"},\"type\":\"array\"},\"prescribers\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentPrescriber\"},\"type\":\"array\"},\"prescriptions\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentPrescription\"},\"type\":\"array\"},\"sites\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentSite\"},\"type\":\"array\"},\"surveys\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentSurvey\"},\"type\":\"array\"},\"thirdPartyCaseId\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"},\"thirdPartyEnrollmentId\":{\"maxLength\":40,\"minLength\":0,\"type\":\"string\"}},\"required\":[\"patient\"],\"type\":\"object\"},\"BasicEnrollmentResponse\":{\"properties\":{\"accountId\":{\"type\":\"number\"},\"claimEligibilityDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"endDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"enrollmentId\":{\"type\":\"number\"},\"enrollmentStatus\":{\"type\":\"string\"},\"isOptedIn\":{\"type\":\"boolean\"},\"maxBenefitAmount\":{\"type\":\"number\"},\"medicalMemberNumber\":{\"type\":\"string\"},\"medicalMemberNumberDetails\":{\"$ref\":\"#/components/schemas/BasicEnrollmentMemberNumberDetails\"},\"messages\":{\"items\":{\"type\":\"string\"},\"type\":\"array\"},\"pharamacyMemberNumber\":{\"type\":\"string\"},\"pharmacyMemberNumberDetails\":{\"$ref\":\"#/components/schemas/BasicEnrollmentMemberNumberDetails\"},\"queuedProcessingDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"reenrollmentEligibilityDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"startDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"untrackedBenefit\":{\"type\":\"boolean\"}},\"required\":[\"accountId\",\"pharamacyMemberNumber\",\"medicalMemberNumber\",\"messages\",\"maxBenefitAmount\",\"untrackedBenefit\",\"startDate\",\"endDate\",\"claimEligibilityDate\",\"reenrollmentEligibilityDate\",\"isOptedIn\",\"pharmacyMemberNumberDetails\",\"medicalMemberNumberDetails\",\"enrollmentId\",\"enrollmentStatus\",\"queuedProcessingDate\"],\"type\":\"object\"},\"BasicEnrollmentSite\":{\"properties\":{\"address\":{\"$ref\":\"#/components/schemas/BasicEnrollmentAddress\"},\"description\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"faxNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"faxNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"},\"phoneNumber\":{\"maxLength\":10,\"minLength\":0,\"type\":\"string\"},\"phoneNumberExtension\":{\"maxLength\":5,\"minLength\":0,\"type\":\"string\"}},\"type\":\"object\"},\"BasicEnrollmentSurvey\":{\"properties\":{\"key\":{\"maxLength\":1024,\"minLength\":0,\"type\":\"string\"},\"questions\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentSurveyQuestion\"},\"type\":\"array\"}},\"required\":[\"key\",\"questions\"],\"type\":\"object\"},\"BasicEnrollmentSurveyAnswer\":{\"properties\":{\"key\":{\"maxLength\":1024,\"minLength\":0,\"type\":\"string\"},\"value\":{\"maxLength\":1024,\"minLength\":0,\"type\":\"string\"}},\"required\":[\"key\",\"value\"],\"type\":\"object\"},\"BasicEnrollmentSurveyQuestion\":{\"properties\":{\"answers\":{\"items\":{\"$ref\":\"#/components/schemas/BasicEnrollmentSurveyAnswer\"},\"type\":\"array\"},\"key\":{\"maxLength\":1024,\"minLength\":0,\"type\":\"string\"}},\"required\":[\"key\",\"answers\"],\"type\":\"object\"},\"BestEnrollmentType\":{\"enum\":[\"Active\",\"Pending\",\"Rejected\"],\"type\":\"string\",\"x-enum-def\":[{\"name\":\"Enrolled\",\"value\":\"Active\"},{\"name\":\"Queued\",\"value\":\"Pending\"},{\"name\":\"Rejected\",\"value\":\"Rejected\"}],\"x-enum-schema\":\"BestEnrollmentType\",\"x-enum-varnames\":[\"Enrolled\",\"Queued\",\"Rejected\"]},\"BestEnrollmentV2Model\":{\"properties\":{\"accountId\":{\"type\":\"number\"},\"benefitPeriodId\":{\"type\":\"number\"},\"bestEnrollmentType\":{\"$ref\":\"#/components/schemas/BestEnrollmentType\"},\"caseId\":{\"type\":\"number\"},\"caseInitiatorId\":{\"type\":\"number\"},\"caseSourceId\":{\"type\":\"number\"},\"caseStatusCode\":{\"type\":\"string\"},\"caseSubStatusCode\":{\"type\":\"string\"},\"claimEligibilityDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"conditionTypeCodeList\":{\"items\":{\"type\":\"string\"},\"type\":\"array\"},\"createDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"endDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"enrollmentFlags\":{\"$ref\":\"#/components/schemas/EnrollmentV2EnrollmentFlags\"},\"householdSize\":{\"type\":\"number\"},\"isOpen\":{\"type\":\"boolean\"},\"isOptedIn\":{\"type\":\"boolean\"},\"isQueued\":{\"type\":\"boolean\"},\"isTest\":{\"type\":\"boolean\"},\"lastOneOrMoreDays\":{\"type\":\"boolean\"},\"linkedEntities\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCaseRelationshipsModel\"},\"maxBenefitAmount\":{\"type\":\"number\"},\"memberNumbers\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentV2MemberNumberModel\"},\"type\":\"array\"},\"paymentType\":{\"type\":\"number\"},\"startDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"status\":{\"$ref\":\"#/components/schemas/EnrollmentV2EligibilityModel\"},\"untrackedBenefit\":{\"type\":\"boolean\"},\"updateCaseIds\":{\"items\":{\"type\":\"number\"},\"type\":\"array\"}},\"required\":[\"bestEnrollmentType\",\"updateCaseIds\",\"memberNumbers\",\"conditionTypeCodeList\"],\"type\":\"object\"},\"ClientEnrollmentControllerGetEnrollmentByExternalIdResponse\":{\"items\":{\"$ref\":\"#/components/schemas/BestEnrollmentV2Model\"},\"type\":\"array\"},\"EdgeEnrollmentV1BasicEnrollmentCreateEnrollmentPostRequest\":{\"type\":\"string\",\"x-apim-inline\":true},\"EdgeEnrollmentV1BasicEnrollmentDeactivateEnrollmentPostRequest\":{\"type\":\"string\",\"x-apim-inline\":true},\"EdgeEnrollmentV1BasicEnrollmentGetEnrollmentByAccountId-accountId-GetRequest\":{\"type\":\"string\",\"x-apim-inline\":true},\"EdgeEnrollmentV1BasicEnrollmentGetEnrollmentByAccountId-accountId-OperationsRequest\":{\"type\":\"string\",\"x-apim-inline\":true},\"EdgeEnrollmentV1BasicEnrollmentGetEnrollmentByExternalIdPostRequest\":{\"type\":\"string\",\"x-apim-inline\":true},\"EdgeEnrollmentV1BasicEnrollmentUpdateEnrollment-accountId-OperationsRequest\":{\"type\":\"number\",\"x-apim-inline\":true},\"EdgeEnrollmentV1BasicEnrollmentUpdateEnrollment-accountId-PostRequest\":{\"type\":\"string\",\"x-apim-inline\":true},\"EnrollPatientCaseInitiator\":{\"enum\":[\"patient\",\"pharmacy\",\"provider\"],\"type\":\"string\",\"x-enum-def\":[{\"name\":\"patient\",\"value\":\"patient\"},{\"name\":\"pharmacy\",\"value\":\"pharmacy\"},{\"name\":\"provider\",\"value\":\"provider\"}],\"x-enum-schema\":\"EnrollPatientCaseInitiator\",\"x-enum-varnames\":[\"patient\",\"pharmacy\",\"provider\"]},\"EnrollPatientCaseSource\":{\"enum\":[\"patientportal\",\"providerportal\"],\"type\":\"string\",\"x-enum-def\":[{\"name\":\"patientportal\",\"value\":\"patientportal\"},{\"name\":\"providerportal\",\"value\":\"providerportal\"}],\"x-enum-schema\":\"EnrollPatientCaseSource\",\"x-enum-varnames\":[\"patientportal\",\"providerportal\"]},\"EnrollmentCheckMemberNumberDefaultResponse\":{\"properties\":{\"data\":{\"$ref\":\"#/components/schemas/EnrollmentIsValidMemberNumberModel\"},\"messages\":{\"items\":{\"type\":\"string\"},\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"EnrollmentIsValidMemberNumberModel\":{\"properties\":{\"inUse\":{\"type\":\"boolean\"},\"isValid\":{\"type\":\"boolean\"},\"memberNumber\":{\"type\":\"string\"},\"memberNumberType\":{\"$ref\":\"#/components/schemas/EnrollmentType\"},\"validationMessage\":{\"type\":\"string\"}},\"type\":\"object\"},\"EnrollmentIsValidMemberNumberRequestModel\":{\"properties\":{\"checkForEnrollment\":{\"type\":\"boolean\"},\"haveACard\":{\"type\":\"boolean\"},\"memberNumber\":{\"type\":\"string\"},\"partyId\":{\"type\":\"number\"}},\"type\":\"object\"},\"EnrollmentNetStandardCaseDocumentRelationshipModel\":{\"properties\":{\"comment\":{\"type\":\"string\"},\"documentId\":{\"type\":\"number\"}},\"type\":\"object\"},\"EnrollmentNetStandardCaseOrderedRelationshipModel\":{\"properties\":{\"coverageOrder\":{\"type\":\"number\"},\"isPrimary\":{\"type\":\"boolean\"},\"partyRoleId\":{\"type\":\"number\"}},\"type\":\"object\"},\"EnrollmentNetStandardCasePrescriptionRelationshipModel\":{\"properties\":{\"documentId\":{\"type\":\"number\"},\"prescriberId\":{\"type\":\"number\"},\"prescriptionId\":{\"type\":\"number\"}},\"type\":\"object\"},\"EnrollmentNetStandardCaseRelationshipModel\":{\"properties\":{\"isPrimary\":{\"type\":\"boolean\"},\"partyRoleId\":{\"type\":\"number\"}},\"type\":\"object\"},\"EnrollmentNetStandardCaseRelationshipsModel\":{\"properties\":{\"documents\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCaseDocumentRelationshipModel\"},\"type\":\"array\"},\"notes\":{\"items\":{\"type\":\"number\"},\"type\":\"array\"},\"payors\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCaseRoleTypeRelationshipModel\"},\"type\":\"array\"},\"pharmacies\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCaseRelationshipModel\"},\"type\":\"array\"},\"prescribers\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCaseRelationshipModel\"},\"type\":\"array\"},\"prescriptions\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCasePrescriptionRelationshipModel\"},\"type\":\"array\"},\"sites\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCaseRelationshipModel\"},\"type\":\"array\"},\"tasks\":{\"items\":{\"type\":\"number\"},\"type\":\"array\"}},\"required\":[\"prescribers\",\"prescriptions\",\"sites\",\"payors\",\"pharmacies\",\"documents\",\"notes\",\"tasks\"],\"type\":\"object\"},\"EnrollmentNetStandardCaseRoleTypeRelationshipModel\":{\"properties\":{\"caseRelations\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentNetStandardCaseOrderedRelationshipModel\"},\"type\":\"array\"},\"roleType\":{\"$ref\":\"#/components/schemas/RoleType\"}},\"required\":[\"caseRelations\"],\"type\":\"object\"},\"EnrollmentStatus\":{\"enum\":[0,1,2,3,4,5,6,7,8,-1,9],\"type\":\"number\",\"x-enum-def\":[{\"name\":\"Approved\",\"value\":0},{\"name\":\"Rejected\",\"value\":1},{\"name\":\"Review_Required\",\"value\":2},{\"name\":\"Review_Processing\",\"value\":3},{\"name\":\"Intake_Processing\",\"value\":4},{\"name\":\"Disenrolled\",\"value\":5},{\"name\":\"Enrolled\",\"value\":6},{\"name\":\"Canceled\",\"value\":7},{\"name\":\"Open\",\"value\":8},{\"name\":\"Unknown\",\"value\":-1},{\"name\":\"EXP\",\"value\":9}],\"x-enum-schema\":\"EnrollmentStatus\",\"x-enum-varnames\":[\"Approved\",\"Rejected\",\"Review_Required\",\"Review_Processing\",\"Intake_Processing\",\"Disenrolled\",\"Enrolled\",\"Canceled\",\"Open\",\"Unknown\",\"EXP\"]},\"EnrollmentStatusResponseModel\":{\"properties\":{\"endDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"enrollmentStatus\":{\"type\":\"string\"},\"medicalMemberNumber\":{\"type\":\"string\"},\"pharmacyMemberNumber\":{\"type\":\"string\"},\"startDate\":{\"format\":\"date-time\",\"type\":\"string\"}},\"required\":[\"pharmacyMemberNumber\",\"medicalMemberNumber\",\"startDate\",\"endDate\",\"enrollmentStatus\"],\"type\":\"object\"},\"EnrollmentType\":{\"enum\":[0,6,7],\"type\":\"number\",\"x-enum-def\":[{\"name\":\"Unknown\",\"value\":0},{\"name\":\"Medical\",\"value\":6},{\"name\":\"Pharmacy\",\"value\":7}],\"x-enum-schema\":\"EnrollmentType\",\"x-enum-varnames\":[\"Unknown\",\"Medical\",\"Pharmacy\"]},\"EnrollmentV2ConditionTypeModel\":{\"properties\":{\"caseId\":{\"type\":\"number\"},\"categoryCode\":{\"type\":\"string\"},\"code\":{\"type\":\"string\"},\"description\":{\"type\":\"string\"}},\"type\":\"object\"},\"EnrollmentV2EligibilityModel\":{\"properties\":{\"conditions\":{\"items\":{\"$ref\":\"#/components/schemas/EnrollmentV2ConditionTypeModel\"},\"type\":\"array\"},\"status\":{\"$ref\":\"#/components/schemas/EnrollmentStatus\"}},\"required\":[\"conditions\"],\"type\":\"object\"},\"EnrollmentV2EnrollmentFlags\":{\"properties\":{\"isActiveEnrollmentForCurrentDate\":{\"type\":\"boolean\"},\"lastOneOrMoreDays\":{\"type\":\"boolean\"}},\"type\":\"object\"},\"EnrollmentV2MemberNumberModel\":{\"properties\":{\"number\":{\"type\":\"string\"},\"offerTypeId\":{\"type\":\"number\"},\"originalPaymentCode\":{\"type\":\"string\"},\"paymentMethod\":{\"type\":\"number\"},\"statusCode\":{\"type\":\"string\"},\"tcProgramId\":{\"type\":\"number\"},\"type\":{\"$ref\":\"#/components/schemas/EnrollmentType\"}},\"type\":\"object\"},\"GatewayError\":{\"properties\":{\"messages\":{\"items\":{\"type\":\"string\"},\"type\":\"array\"},\"success\":{\"type\":\"boolean\"}},\"type\":\"object\",\"x-id\":\"GatewayError\"},\"GetEnrollmentByExternalIdRequestModel\":{\"properties\":{\"accountExternalIdType\":{\"$ref\":\"#/components/schemas/AccountExternalIdType\"},\"externalId\":{\"type\":\"string\"}},\"required\":[\"externalId\",\"accountExternalIdType\"],\"type\":\"object\"},\"GetEnrollmentStatusRequestModel\":{\"properties\":{\"dateOfBirth\":{\"format\":\"date-time\",\"type\":\"string\"},\"firstName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"gender\":{\"$ref\":\"#/components/schemas/BasicEnrollmentGender\"},\"lastName\":{\"maxLength\":120,\"minLength\":0,\"type\":\"string\"},\"zip\":{\"maxLength\":5,\"minLength\":5,\"type\":\"string\"}},\"required\":[\"firstName\",\"lastName\",\"dateOfBirth\"],\"type\":\"object\"},\"RoleType\":{\"enum\":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63],\"type\":\"number\",\"x-enum-def\":[{\"name\":\"Unknown\",\"value\":0},{\"name\":\"Patient\",\"value\":1},{\"name\":\"Prescriber\",\"value\":2},{\"name\":\"InsuranceProvider\",\"value\":3},{\"name\":\"PharmacyBenefitManager\",\"value\":4},{\"name\":\"SecondaryContact\",\"value\":5},{\"name\":\"Manufacturer\",\"value\":6},{\"name\":\"EMP\",\"value\":7},{\"name\":\"CustomerServiceRep\",\"value\":8},{\"name\":\"PrescriberSite\",\"value\":9},{\"name\":\"Brand\",\"value\":10},{\"name\":\"Child\",\"value\":11},{\"name\":\"SocialWorker\",\"value\":12},{\"name\":\"FinancialRepresentative\",\"value\":13},{\"name\":\"LegalRepresentative\",\"value\":14},{\"name\":\"Corporate\",\"value\":15},{\"name\":\"PersonalContact\",\"value\":16},{\"name\":\"Spouse\",\"value\":17},{\"name\":\"Parent\",\"value\":18},{\"name\":\"HomeHealth\",\"value\":19},{\"name\":\"AlternateContact\",\"value\":20},{\"name\":\"AutoInjuryPlan\",\"value\":21},{\"name\":\"CommercialPlan\",\"value\":22},{\"name\":\"FederalEmployeeProgram\",\"value\":23},{\"name\":\"Medicaid\",\"value\":24},{\"name\":\"MedicareAdvantage\",\"value\":25},{\"name\":\"MedicareB\",\"value\":26},{\"name\":\"MedicareD\",\"value\":27},{\"name\":\"MediGap\",\"value\":28},{\"name\":\"VADoDTRICARE\",\"value\":29},{\"name\":\"WorkersCompensation\",\"value\":30},{\"name\":\"Plan\",\"value\":31},{\"name\":\"Payer\",\"value\":32},{\"name\":\"DurableMedicalEquiqmentPlan\",\"value\":33},{\"name\":\"ManagedCareMedicaidPlan\",\"value\":34},{\"name\":\"StatePharmacyAssistanceProgram\",\"value\":35},{\"name\":\"MedicarePartABPlan\",\"value\":36},{\"name\":\"AidsDrugAssistanceProgram\",\"value\":37},{\"name\":\"StatePlan\",\"value\":38},{\"name\":\"Provider\",\"value\":39},{\"name\":\"ExclusiveProviderOrganization\",\"value\":40},{\"name\":\"IndemnityInsurance\",\"value\":41},{\"name\":\"HealthMaintenanceOrganization\",\"value\":42},{\"name\":\"PointOfServicePlan\",\"value\":43},{\"name\":\"PreferredProviderOrganization\",\"value\":44},{\"name\":\"Self\",\"value\":45},{\"name\":\"OfficeContact\",\"value\":46},{\"name\":\"Pharmacy\",\"value\":47},{\"name\":\"MedicareA\",\"value\":48},{\"name\":\"Hospital\",\"value\":49},{\"name\":\"HospitalOutpatient\",\"value\":50},{\"name\":\"InfusionCenter\",\"value\":51},{\"name\":\"RetailPharmacy\",\"value\":52},{\"name\":\"Foundation\",\"value\":53},{\"name\":\"SecondarySupplemental\",\"value\":54},{\"name\":\"RegisteredNurse\",\"value\":55},{\"name\":\"LicensedPracticalNurse\",\"value\":56},{\"name\":\"CertifiedNursingAssistant\",\"value\":57},{\"name\":\"MedicalAssistant\",\"value\":58},{\"name\":\"NationalHomeHealthAgency\",\"value\":59},{\"name\":\"IndependentHomeHealthAgency\",\"value\":60},{\"name\":\"Practice\",\"value\":61},{\"name\":\"PerDiemContractIndividual\",\"value\":62},{\"name\":\"Employee\",\"value\":63}],\"x-enum-schema\":\"RoleType\",\"x-enum-varnames\":[\"Unknown\",\"Patient\",\"Prescriber\",\"InsuranceProvider\",\"PharmacyBenefitManager\",\"SecondaryContact\",\"Manufacturer\",\"EMP\",\"CustomerServiceRep\",\"PrescriberSite\",\"Brand\",\"Child\",\"SocialWorker\",\"FinancialRepresentative\",\"LegalRepresentative\",\"Corporate\",\"PersonalContact\",\"Spouse\",\"Parent\",\"HomeHealth\",\"AlternateContact\",\"AutoInjuryPlan\",\"CommercialPlan\",\"FederalEmployeeProgram\",\"Medicaid\",\"MedicareAdvantage\",\"MedicareB\",\"MedicareD\",\"MediGap\",\"VADoDTRICARE\",\"WorkersCompensation\",\"Plan\",\"Payer\",\"DurableMedicalEquiqmentPlan\",\"ManagedCareMedicaidPlan\",\"StatePharmacyAssistanceProgram\",\"MedicarePartABPlan\",\"AidsDrugAssistanceProgram\",\"StatePlan\",\"Provider\",\"ExclusiveProviderOrganization\",\"IndemnityInsurance\",\"HealthMaintenanceOrganization\",\"PointOfServicePlan\",\"PreferredProviderOrganization\",\"Self\",\"OfficeContact\",\"Pharmacy\",\"MedicareA\",\"Hospital\",\"HospitalOutpatient\",\"InfusionCenter\",\"RetailPharmacy\",\"Foundation\",\"SecondarySupplemental\",\"RegisteredNurse\",\"LicensedPracticalNurse\",\"CertifiedNursingAssistant\",\"MedicalAssistant\",\"NationalHomeHealthAgency\",\"IndependentHomeHealthAgency\",\"Practice\",\"PerDiemContractIndividual\",\"Employee\"]}}}"
#   content_type        = "application/vnd.oai.openapi.components+json"
#   resource_group_name = data.azurerm_resource_group.rg_deployment.name
#   schema_id           = "6398d93f01234e1780d58aef"

#   depends_on = [
#     azurerm_api_management_api.api_trialcard_api_gateway,
#   ]
# }
resource "azurerm_api_management_backend" "api_management_backend_eservices_orchestrator" {
  api_management_name = data.azurerm_api_management.apim.name
  name                = "eservices-orchestrator"
  protocol            = "http"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url                 = var.backend_eservicesorchestrator
  tls {
    validate_certificate_chain = true
    validate_certificate_name  = true
  }

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
resource "azurerm_api_management_backend" "api_management_backend_apigateway" {
  api_management_name = data.azurerm_api_management.apim.name
  name                = "apigateway"
  protocol            = "http"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url                 = var.backend_apigateway
  tls {
    validate_certificate_chain = true
    validate_certificate_name  = true
  }

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
resource "azurerm_api_management_backend" "api_management_backend_salesforce_intsvc" {
  api_management_name = data.azurerm_api_management.apim.name
  description         = "salesforce-intsvc"
  name                = "salesforce-intsvc"
  protocol            = "http"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  # resource_id         = azurerm_linux_function_app.tc_function_app.id
  url = "https://${azurerm_linux_function_app.tc_function_app.default_hostname}/api"
  credentials {
    header = {
      x-functions-key = "{{salesforce-intsvc-key}}"
    }
  }

  depends_on = [
    data.azurerm_api_management.apim,
    azurerm_api_management_named_value.salesforce-intsvc-key,
  ]
}
# resource "azurerm_api_management_diagnostic" "res-118" {
#   api_management_logger_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat/loggers/Apim_Ai"
#   api_management_name      = data.azurerm_api_management.apim.name
#   identifier               = "applicationinsights"
#   resource_group_name      = data.azurerm_resource_group.rg_deployment.name
#   depends_on = [
#     azurerm_api_management_logger.res-127,
#   ]
# }
# resource "azurerm_api_management_logger" "res-127" {
#   api_management_name = data.azurerm_api_management.apim.name
#   name                = "Apim_Ai"
#  resource_group_name = data.azurerm_resource_group.rg_deployment.name
#   resource_id         = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-core-01/providers/microsoft.insights/components/Apim_Ai"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_logger" "res-128" {
#   api_management_name = data.azurerm_api_management.apim.name
#   name                = "azuremonitor"
#  resource_group_name = data.azurerm_resource_group.rg_deployment.name
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
resource "azurerm_api_management_named_value" "auth0DefaultClientId" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "auth0DefaultClientId"
  name                = "auth0DefaultClientId"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  value               = var.auth0DefaultClientId
  secret              = true

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
# resource "azurerm_api_management_named_value" "res-129" {
#   api_management_name = data.azurerm_api_management.apim.name
#   display_name        = "Logger-Credentials--634dc9d301234e1460957bf4"
#   name                = "634dc9d301234e1460957bf3"
#  resource_group_name = data.azurerm_resource_group.rg_deployment.name
#   secret              = true
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
resource "azurerm_api_management_named_value" "auth0AuthorizationServer" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "auth0AuthorizationServer"
  name                = "auth0AuthorizationServer"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  value               = var.auth0AuthorizationServer

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
resource "azurerm_api_management_named_value" "auth0DefaultClientSecret" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "auth0DefaultClientSecret"
  name                = "auth0DefaultClientSecret"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  value               = var.auth0DefaultClientSecret
  secret              = true

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
resource "azurerm_api_management_named_value" "enrollment-audience" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "enrollment-audience"
  name                = "enrollment-audience"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  value               = "https://apigateway.trialcard.com"

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
resource "azurerm_api_management_named_value" "eservices-orchestrator-audience" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "eservices-orchestrator-audience"
  name                = "eservices-orchestrator-audience"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  value               = var.eservicesOrchestratorAudience

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
resource "azurerm_api_management_named_value" "eservices-orchestrator-programid" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "eservices-orchestrator-programid"
  name                = "eservices-orchestrator-programid"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  value               = var.eservicesOrchestratorProgramid

  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
resource "azurerm_api_management_named_value" "salesforce-intsvc-key" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "salesforce-intsvc-key"
  name                = "salesforce-intsvc-key"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  secret              = true
  value               = data.azurerm_function_app_host_keys.tc_function_app_key.default_function_key
  tags                = ["key", "function", "auto"]
  
  depends_on = [
    data.azurerm_api_management.apim,
  ]
}



resource "azurerm_api_management_named_value" "salesforce-intsvc-url" {
  api_management_name = data.azurerm_api_management.apim.name
  display_name        = "salesforce-intsvc-url"
  name                = "salesforce-intsvc-url"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  value               = "https://${azurerm_linux_function_app.tc_function_app.default_hostname}/api"
  depends_on = [
    data.azurerm_api_management.apim,
  ]
}
# resource "azurerm_api_management_policy" "api_management_policy_default" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   xml_content       = "<!--\r\n    IMPORTANT:\r\n    - Policy elements can appear only within the <inbound>, <outbound>, <backend> section elements.\r\n    - Only the <forward-request> policy element can appear within the <backend> section element.\r\n    - To apply a policy to the incoming request (before it is forwarded to the backend service), place a corresponding policy element within the <inbound> section element.\r\n    - To apply a policy to the outgoing response (before it is sent back to the caller), place a corresponding policy element within the <outbound> section element.\r\n    - To add a policy position the cursor at the desired insertion point and click on the round button associated with the policy.\r\n    - To remove a policy, delete the corresponding policy statement from the policy document.\r\n    - Policies are applied in the order of their appearance, from the top down.\r\n-->\r\n<policies>\r\n\t<inbound />\r\n\t<backend>\r\n\t\t<forward-request />\r\n\t</backend>\r\n\t<outbound />\r\n</policies>"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "api_management_tag_configuration" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "Configuration"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "api_management_tag_default" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "Default"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-179" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "Enrollment"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-180" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ExternalSystem"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-181" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ExternalSystemActivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-182" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ExternalSystemDeactivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-183" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "Logging"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-184" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "MedicalBi"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-185" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "MedicalBiRequestSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-186" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "MedicalBiResultSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-187" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "MedicalEligibility"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-188" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "MedicalEligibilityRequestSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-189" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "MedicalEligibilityResultSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-191" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "PharmacyBiRequestSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-190" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "PharmacyBi"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-193" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "PharmacyCardFinder"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-192" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "PharmacyBiResultSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-194" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "PharmacyCardFinderRequestSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-195" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "PharmacyCardFinderResultSearch"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-196" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "Program"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-197" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramActivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-199" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramNdc"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-198" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramDeactivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-200" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramNdcActivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-201" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramNdcDeactivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-202" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramService"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-203" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramServiceActivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-204" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ProgramServiceDeactivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-205" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "Service"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-206" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ServiceActivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-208" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ServiceProvider"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-207" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ServiceDeactivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-209" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ServiceProviderActivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-211" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ServiceType"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-210" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ServiceProviderDeactivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
# resource "azurerm_api_management_tag" "res-212" {
#   api_management_id = "/subscriptions/00f3857f-94bd-4105-ab4e-3909798a62fa/resourceGroups/rg-salesforce-uat-apim/providers/Microsoft.ApiManagement/service/apim-TrialCardAPIM-cus-uat"
#   name              = "ServiceTypeActivate"
#   depends_on = [
#     data.azurerm_api_management.apim,
#   ]
# }
