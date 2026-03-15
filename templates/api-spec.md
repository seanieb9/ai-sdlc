openapi: 3.1.0
info:
  title: {{SERVICE_NAME}} API
  version: 1.0.0
  description: |
    {{Service description}}

    ## Authentication
    All endpoints require Bearer token in Authorization header unless marked public.

    ## Error Format
    All errors return:
    ```json
    {
      "code": "MACHINE_READABLE_CODE",
      "message": "Human readable message",
      "fields": [{"field": "name", "message": "Validation message"}],
      "trace_id": "For support reference"
    }
    ```

    ## Versioning
    Breaking changes increment the major version (/api/v2/).

servers:
  - url: https://api.{{domain}}/api/v1
    description: Production
  - url: https://api-staging.{{domain}}/api/v1
    description: Staging

security:
  - bearerAuth: []

paths:
  /{{resources}}:
    post:
      summary: Create {{resource}}
      operationId: create_{{resource}}
      tags:
        - {{Resource}}
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Create{{Resource}}Request'
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{{Resource}}Response'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '422':
          $ref: '#/components/responses/ValidationError'
        '500':
          $ref: '#/components/responses/InternalError'

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  responses:
    BadRequest:
      description: Bad request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    Forbidden:
      description: Insufficient permissions
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    ValidationError:
      description: Validation failed
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ValidationErrorResponse'
    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

  schemas:
    ErrorResponse:
      type: object
      required: [code, message, trace_id]
      properties:
        code:
          type: string
          example: NOT_FOUND
        message:
          type: string
          example: Resource not found
        trace_id:
          type: string
          example: 4bf92f3577b34da6a3ce929d0e0e4736

    ValidationErrorResponse:
      allOf:
        - $ref: '#/components/schemas/ErrorResponse'
        - type: object
          properties:
            fields:
              type: array
              items:
                type: object
                required: [field, message]
                properties:
                  field:
                    type: string
                  message:
                    type: string

    PaginatedResponse:
      type: object
      required: [data, pagination]
      properties:
        data:
          type: array
        pagination:
          type: object
          required: [cursor, has_more, total]
          properties:
            cursor:
              type: string
              nullable: true
            has_more:
              type: boolean
            total:
              type: integer
