resource "azurerm_api_management_api_operation" "api_operation_FulfillmentCreate" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "FulfillmentCreate"
  method              = "POST"
  operation_id        = "FulfillmentCreate"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/FulfillmentCreate"
  response {
    description = "Payload of CreateFulfillmentResponse"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "createFulfillmentResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"streamId\":0,\"streamMemberAttemptId\":0}"
    #   }
    # }
  }
  response {
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "problemDetails"
    #   example {
    #     name  = "default"
    #     value = "{\"detail\":\"string\",\"instance\":\"string\",\"status\":0,\"title\":\"string\",\"type\":\"string\"}"
    #   }
    # }
  }
  
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}

resource "azurerm_api_management_api" "api_campaign_and_document" {
  api_management_name   = data.azurerm_api_management.apim.name
  description           = "This is the OpenAPI Document on Azure Functions"
  name                  = "campaign-and-document"
  display_name          = "campaign-and-document"
  path = "cnd"
  resource_group_name   = data.azurerm_resource_group.rg_deployment.name
  revision              = "1"
  subscription_required = false
  protocols             = ["https"]
  depends_on = [
    data.azurerm_api_management.apim,
  ]
}

resource "azurerm_api_management_api_operation" "api_operation_DocumentSplitDocument" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "DocumentSplitDocument"
  method              = "POST"
  operation_id        = "DocumentSplitDocument"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/DocumentSplitDocument"
  response {
    description = "Payload of SplitDocumentResponse"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "splitDocumentResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"documents\":[{\"documentId\":0}]}"
    #   }
    # }
  }
  response {
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "problemDetails"
    #   example {
    #     name  = "default"
    #     value = "{\"detail\":\"string\",\"instance\":\"string\",\"status\":0,\"title\":\"string\",\"type\":\"string\"}"
    #   }
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}

resource "azurerm_api_management_api_operation" "api_operation_DocumentUploadDocument" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "DocumentUploadDocument"
  method              = "POST"
  operation_id        = "DocumentUploadDocument"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/fulfillment/upload/{programCode}"
  response {
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "uploadDocumentResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"documentId\":0}"
    #   }
    # }
  }
  response {
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "problemDetails"
    #   example {
    #     name  = "default"
    #     value = "{\"detail\":\"string\",\"instance\":\"string\",\"status\":0,\"title\":\"string\",\"type\":\"string\"}"
    #   }
    # }
  }
  template_parameter {
    name     = "programCode"
    required = true
    type     = ""
  }
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}

resource "azurerm_api_management_api_operation" "api_operation_DocumentGetDocumentById" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "DocumentGetDocumentById"
  method              = "GET"
  operation_id        = "DocumentGetDocumentById"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/fulfillment/getDocumentById/{programCode}/{documentId}"
  response {
    description = "Payload of GetDocumentByIdResponse"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "getDocumentByIdResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"createdDate\":\"string\",\"documentData\":\"string\",\"mimeType\":\"string\",\"processedDate\":\"string\",\"updatedDate\":\"string\"}"
    #   }
    # }
  }
  response {
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "problemDetails"
    #   example {
    #     name  = "default"
    #     value = "{\"detail\":\"string\",\"instance\":\"string\",\"status\":0,\"title\":\"string\",\"type\":\"string\"}"
    #   }
    # }
  }
  template_parameter {
    name     = "programCode"
    required = true
    type     = "string"
  }
  template_parameter {
    name     = "documentId"
    required = true
    type     = "string"
  }
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}

resource "azurerm_api_management_api_operation" "api_operation_FulfillmentGetStatus" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "FulfillmentGetStatus"
  method              = "POST"
  operation_id        = "FulfillmentGetStatus"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/FulfillmentGetStatus"
  response {
    description = "Payload of GetFulfillmentStatusesResponse"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "getFulfillmentStatusesResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"attempts\":[{\"attemptDate\":\"string\",\"attemptStatus\":\"string\",\"attemptStatusDescription\":\"string\",\"customData\":[{\"createDate\":\"string\",\"key\":\"string\",\"lastUpdatedDate\":\"string\",\"value\":\"string\"}],\"responseType\":\"string\",\"responseTypeDescription\":\"string\",\"resultMessage\":\"string\",\"streamId\":0,\"streamMemberAttemptId\":0}]}"
    #   }
    # }
  }
  response {
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "problemDetails"
    #   example {
    #     name  = "default"
    #     value = "{\"detail\":\"string\",\"instance\":\"string\",\"status\":0,\"title\":\"string\",\"type\":\"string\"}"
    #   }
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_TestTrigger" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "TestTrigger"
  method              = "POST"
  operation_id        = "post-testtrigger"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/TestTrigger"
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_FulfillmentPreview" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "FulfillmentPreview"
  method              = "POST"
  operation_id        = "FulfillmentPreview"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/FulfillmentPreview"
  response {
    description = "Payload of FulfillmentPreviewResponse"
    status_code = 200
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "fulfillmentPreviewResponse"
    #   example {
    #     name  = "default"
    #     value = "{\"documentData\":\"string\",\"mimeType\":\"string\"}"
    #   }
    # }
  }
  response {
    status_code = 400
    # representation {
    #   content_type = "application/json"
    #   schema_id    = "63617ee301234e10c89f19a2"
    #   type_name    = "problemDetails"
    #   example {
    #     name  = "default"
    #     value = "{\"detail\":\"string\",\"instance\":\"string\",\"status\":0,\"title\":\"string\",\"type\":\"string\"}"
    #   }
    # }
  }
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}
resource "azurerm_api_management_api_operation" "api_operation_TestHealth" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  display_name        = "TestHealth"
  method              = "POST"
  operation_id        = "post-testhealth"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  url_template        = "/TestHealth"
  depends_on = [
    azurerm_api_management_api.api_campaign_and_document,
  ]
}
# resource "azurerm_api_management_api_schema" "api_schema_63617ee301234e10c89f19a2" {
#   api_management_name = data.azurerm_api_management.apim.name
#   api_name            = "campaign-and-document"
#   content_type        = "application/vnd.ms-azure-apim.swagger.definitions+json"
#   definitions         = "{\"createFulfillmentRequest\":{\"properties\":{\"attachedDocuments\":{\"items\":{\"format\":\"int64\",\"type\":\"integer\"},\"type\":\"array\"},\"customData\":{\"items\":{\"$ref\":\"#/definitions/customDataRequest\"},\"type\":\"array\"},\"programCode\":{\"type\":\"string\"},\"streamId\":{\"format\":\"int64\",\"type\":\"integer\"}},\"type\":\"object\"},\"createFulfillmentResponse\":{\"properties\":{\"streamId\":{\"format\":\"int64\",\"type\":\"integer\"},\"streamMemberAttemptId\":{\"format\":\"int64\",\"type\":\"integer\"}},\"type\":\"object\"},\"customDataRequest\":{\"properties\":{\"key\":{\"type\":\"string\"},\"value\":{\"type\":\"string\"}},\"type\":\"object\"},\"customDataResponse\":{\"properties\":{\"createDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"key\":{\"type\":\"string\"},\"lastUpdatedDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"value\":{\"type\":\"string\"}},\"type\":\"object\"},\"fulfillmentPreviewRequest\":{\"properties\":{\"customData\":{\"items\":{\"$ref\":\"#/definitions/customDataRequest\"},\"type\":\"array\"},\"programCode\":{\"type\":\"string\"},\"streamId\":{\"format\":\"int64\",\"type\":\"integer\"}},\"type\":\"object\"},\"fulfillmentPreviewResponse\":{\"properties\":{\"documentData\":{\"format\":\"binary\",\"type\":\"string\"},\"mimeType\":{\"type\":\"string\"}},\"type\":\"object\"},\"getDocumentByIdResponse\":{\"properties\":{\"createdDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"documentData\":{\"format\":\"binary\",\"type\":\"string\"},\"mimeType\":{\"type\":\"string\"},\"processedDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"updatedDate\":{\"format\":\"date-time\",\"type\":\"string\"}},\"type\":\"object\"},\"getFulfillmentStatusRequest\":{\"properties\":{\"streamId\":{\"format\":\"int64\",\"type\":\"integer\"},\"streamMemberAttemptId\":{\"format\":\"int64\",\"type\":\"integer\"}},\"type\":\"object\"},\"getFulfillmentStatusResponse\":{\"properties\":{\"attemptDate\":{\"format\":\"date-time\",\"type\":\"string\"},\"attemptStatus\":{\"type\":\"string\"},\"attemptStatusDescription\":{\"type\":\"string\"},\"customData\":{\"items\":{\"$ref\":\"#/definitions/customDataResponse\"},\"type\":\"array\"},\"responseType\":{\"type\":\"string\"},\"responseTypeDescription\":{\"type\":\"string\"},\"resultMessage\":{\"type\":\"string\"},\"streamId\":{\"format\":\"int64\",\"type\":\"integer\"},\"streamMemberAttemptId\":{\"format\":\"int64\",\"type\":\"integer\"}},\"type\":\"object\"},\"getFulfillmentStatusesRequest\":{\"properties\":{\"attempts\":{\"items\":{\"$ref\":\"#/definitions/getFulfillmentStatusRequest\"},\"type\":\"array\"}},\"type\":\"object\"},\"getFulfillmentStatusesResponse\":{\"properties\":{\"attempts\":{\"items\":{\"$ref\":\"#/definitions/getFulfillmentStatusResponse\"},\"type\":\"array\"}},\"type\":\"object\"},\"problemDetails\":{\"nullable\":true,\"properties\":{\"detail\":{\"nullable\":true,\"type\":\"string\"},\"instance\":{\"nullable\":true,\"type\":\"string\"},\"status\":{\"format\":\"int32\",\"nullable\":true,\"type\":\"integer\"},\"title\":{\"type\":\"string\"},\"type\":{\"type\":\"string\"}},\"required\":[\"title\",\"type\"],\"type\":\"object\"},\"splitDocumentData\":{\"properties\":{\"pages\":{\"items\":{\"format\":\"int32\",\"type\":\"integer\"},\"type\":\"array\"}},\"type\":\"object\"},\"splitDocumentRequest\":{\"properties\":{\"documentId\":{\"format\":\"int64\",\"type\":\"integer\"},\"programCode\":{\"type\":\"string\"},\"splitData\":{\"items\":{\"$ref\":\"#/definitions/splitDocumentData\"},\"type\":\"array\"}},\"type\":\"object\"},\"splitDocumentResponse\":{\"properties\":{\"documents\":{\"items\":{\"$ref\":\"#/definitions/splitDocumentResult\"},\"type\":\"array\"}},\"type\":\"object\"},\"splitDocumentResult\":{\"properties\":{\"documentId\":{\"format\":\"int64\",\"type\":\"integer\"}},\"type\":\"object\"},\"uploadDocumentRequest\":{\"properties\":{\"fileContent\":{\"format\":\"byte\",\"type\":\"string\"},\"fileName\":{\"type\":\"string\"}},\"type\":\"object\"},\"uploadDocumentResponse\":{\"properties\":{\"documentId\":{\"format\":\"int64\",\"type\":\"integer\"}},\"type\":\"object\"}}"
#   resource_group_name = data.azurerm_resource_group.rg_deployment.name
#   schema_id           = "63617ee301234e10c89f19a2"
#   depends_on = [
#     azurerm_api_management_api.api_campaign_and_document,
#   ]
# }
resource "azurerm_api_management_api_policy" "api_management_policy_campaign-and-document" {
  api_management_name = data.azurerm_api_management.apim.name
  api_name            = "campaign-and-document"
  resource_group_name = data.azurerm_resource_group.rg_deployment.name
  xml_content         = <<EOT
<policies>
    <inbound>
        <set-backend-service id="apim-generated-policy" backend-id="salesforce-intsvc" />
        <base />
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
    azurerm_api_management_api.api_campaign_and_document,
    azurerm_api_management_backend.api_management_backend_salesforce_intsvc,
  ]
}
