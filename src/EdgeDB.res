module Transaction = {
  type t

  @module("edgedb") external make: unit => t = "createClient"

  @send external execute: (t, string, ~args: 'args=?) => promise<unit> = "execute"

  @send external query: (t, string, ~args: 'args=?) => promise<array<'result>> = "query"
  @send external queryJSON: (t, string, ~args: 'args=?) => promise<string> = "queryJSON"

  @send
  external querySingle: (t, string, ~args: 'args=?) => promise<Null.t<'result>> = "querySingle"
  @send
  external querySingleJSON: (t, string, ~args: 'args=?) => promise<string> = "querySingleJSON"

  @send @raises(JsError)
  external queryRequiredSingle: (t, string, ~args: 'args=?) => promise<'result> =
    "queryRequiredSingle"

  @send @raises(JsError)
  external queryRequiredSingleJSON: (t, string, ~args: 'args=?) => promise<string> =
    "queryRequiredSingleJSON"
}

module Session = {
  type t
}

module Duration = {
  type durationLike = {
    years?: float,
    months?: float,
    weeks?: float,
    days?: float,
    hours?: float,
    minutes?: float,
    seconds?: float,
    milliseconds?: float,
    microseconds?: float,
    nanoseconds?: float,
  }

  type t
  @send external from: durationLike => t = "from"
  @send external fromDuration: t => t = "from"
  @send external fromString: string => t = "from"
}

module Client = {
  /* Creating and configuring the client */
  type t

  type tlsSecurity =
    | @as("insecure") Insecure
    | @as("no_host_verification") NoHostVerification
    | @as("strict") Strict
    | @as("default") Default

  type connectConfig = {
    dsn?: string,
    instanceName?: string,
    credentials?: string,
    credentialsFile?: string,
    host?: string,
    port?: int,
    database?: string,
    user?: string,
    password?: string,
    secretKey?: string,
    serverSettings?: unknown,
    tlsCA?: string,
    tlsCAFile?: string,
    tlsSecurity?: tlsSecurity,
    timeout?: int,
    waitUntilAvailable?: Duration.t,
    logging?: bool,
  }
  type clientOptions = {concurrency?: int}
  type connectOptions = {...clientOptions, ...connectConfig}

  type resolvedConnectConfig = {
    address: (string, float),
    database: string,
    user: string,
    password: option<string>,
    secretKey: option<string>,
    cloudProfile: string,
    tlsSecurity: tlsSecurity,
    waitUntilAvailable: float,
  }

  type partiallyNormalizedConfig = {
    connectionParams: resolvedConnectConfig,
    inProject: unit => promise<bool>,
    fromProject: bool,
    fromEnv: bool,
  }
  type normalizedConnectConfig = {
    ...partiallyNormalizedConfig,
    connectTimeout?: float,
    logging: bool,
  }

  @module("edgedb") external make: (~options: connectOptions=?) => t = "createClient"

  @unboxed
  type isolationLevel = | @as("SERIALIZABLE") Serializable

  type simpleTransactionOptions = {
    isolation?: isolationLevel,
    readonly?: bool,
    deferrable?: bool,
  }

  @send
  external withTransactionOptions: (t, simpleTransactionOptions) => t = "withTransactionOptions"

  type simpleRetryOptions = {
    attempts?: int,
    /** (attempt: int) => float */
    backoff?: int => float,
  }

  @send
  external withRetryOptions: (t, simpleRetryOptions) => t = "withRetryOptions"

  @send
  external withSession: (t, Session.t) => t = "withSession"

  @send
  external withModuleAliases: (t, Dict.t<string>) => t = "withModuleAliases"

  type allowBareDdl = AlwaysAllow | NeverAllow

  type simpleConfig = {
    @as("session_idle_transaction_timeout") sessionIdleTransactionTimeout?: Duration.t,
    @as("query_execution_timeout") queryExecutionTimeout?: Duration.t,
    @as("allow_bare_ddl") allowBareDdl?: allowBareDdl,
    @as("allow_dml_in_functions") allowDmlInFunctions?: bool,
    @as("allow_user_specified_id") allowUserSpecifiedId?: bool,
    @as("apply_access_policies") applyAccessPolicies?: bool,
  }

  @send
  external withConfig: (t, simpleConfig) => t = "withConfig"

  @send
  external withGlobals: (t, Dict.t<JSON.t>) => t = "withGlobals"

  /* Status */
  @send @raises(JsError)
  external ensureConnected: t => promise<unit> = "ensureConnected"

  @send
  external isClosed: t => bool = "isClosed"

  @send
  external close: t => promise<unit> = "close"

  @send
  external terminate: t => unit = "terminate"

  /* Execution */

  @send external execute: (t, string, ~args: 'args=?) => promise<unit> = "execute"

  @send external query: (t, string, ~args: 'args=?) => promise<array<'result>> = "query"
  @send external queryJSON: (t, string, ~args: 'args=?) => promise<string> = "queryJSON"

  @send
  external querySingle: (t, string, ~args: 'args=?) => promise<Null.t<'result>> = "querySingle"
  @send
  external querySingleJSON: (t, string, ~args: 'args=?) => promise<string> = "querySingleJSON"

  @send
  external queryRequiredSingle: (t, string, ~args: 'args=?) => promise<'result> =
    "queryRequiredSingle"

  @send
  external queryRequiredSingleJSON: (t, string, ~args: 'args=?) => promise<string> =
    "queryRequiredSingleJSON"

  @send
  external transaction: (t, Transaction.t => promise<'result>) => promise<'result> = "transaction"
}

module Error = {
  @tag("code")
  type binaryProtocolError =
    | @as(0x03_01_00_00) BinaryProtocolError
    | @as(0x03_01_00_01) UnsupportedProtocolVersionError
    | @as(0x03_01_00_02) TypeSpecNotFoundError
    | @as(0x03_01_00_03) UnexpectedMessageError

  @tag("code")
  type inputDataError =
    | @as(0x03_02_00_00) InputDataError
    | @as(0x03_02_01_00) ParameterTypeMismatchError
    | @as(0x03_02_02_00) StateMismatchError

  @tag("code")
  type capabilityError =
    | @as(0x03_04_00_00) CapabilityError
    | @as(0x03_04_01_00) UnsupportedCapabilityError
    | @as(0x03_04_02_00) DisabledCapabilityError

  @tag("code")
  type protocolError =
    | @as(0x03_00_00_00) ProtocolError
    | @as(0x03_03_00_00) ResultCardinalityMismatchError
    | ...binaryProtocolError
    | ...inputDataError
    | ...capabilityError

  @tag("code")
  type invalidSyntaxError =
    | @as(0x04_01_00_00) InvalidSyntaxError
    | @as(0x04_01_01_00) EdgeQLSyntaxError
    | @as(0x04_01_02_00) SchemaSyntaxError
    | @as(0x04_01_03_00) GraphQLSyntaxError

  @tag("code")
  type invalidTargetError =
    | @as(0x04_02_01_00) InvalidTargetError
    | @as(0x04_02_01_01) InvalidLinkTargetError
    | @as(0x04_02_01_02) InvalidPropertyTargetError

  @tag("code")
  type invalidTypeError = | @as(0x04_02_00_00) InvalidTypeError | ...invalidTargetError

  @tag("code")
  type invalidReferenceError =
    | @as(0x04_03_00_00) InvalidReferenceError
    | @as(0x04_03_00_01) UnknownModuleError
    | @as(0x04_03_00_02) UnknownLinkError
    | @as(0x04_03_00_03) UnknownPropertyError
    | @as(0x04_03_00_04) UnknownUserError
    | @as(0x04_03_00_05) UnknownDatabaseError
    | @as(0x04_03_00_06) UnknownParameterError

  @tag("code")
  type invalidDefinitionError =
    | @as(0x04_05_01_00) InvalidDefinitionError
    | @as(0x04_05_01_01) InvalidModuleDefinitionError
    | @as(0x04_05_01_02) InvalidLinkDefinitionError
    | @as(0x04_05_01_03) InvalidPropertyDefinitionError
    | @as(0x04_05_01_04) InvalidUserDefinitionError
    | @as(0x04_05_01_05) InvalidDatabaseDefinitionError
    | @as(0x04_05_01_06) InvalidOperatorDefinitionError
    | @as(0x04_05_01_07) InvalidAliasDefinitionError
    | @as(0x04_05_01_08) InvalidFunctionDefinitionError
    | @as(0x04_05_01_09) InvalidConstraintDefinitionError
    | @as(0x04_05_01_0a) InvalidCastDefinitionError

  @tag("code")
  type duplicateDefinitionError =
    | @as(0x04_05_02_00) DuplicateDefinitionError
    | @as(0x04_05_02_01) DuplicateModuleDefinitionError
    | @as(0x04_05_02_02) DuplicateLinkDefinitionError
    | @as(0x04_05_02_03) DuplicatePropertyDefinitionError
    | @as(0x04_05_02_04) DuplicateUserDefinitionError
    | @as(0x04_05_02_05) DuplicateDatabaseDefinitionError
    | @as(0x04_05_02_06) DuplicateOperatorDefinitionError
    | @as(0x04_05_02_07) DuplicateViewDefinitionError
    | @as(0x04_05_02_08) DuplicateFunctionDefinitionError
    | @as(0x04_05_02_09) DuplicateConstraintDefinitionError
    | @as(0x04_05_02_0a) DuplicateCastDefinitionError
    | @as(0x04_05_02_0b) DuplicateMigrationError

  @tag("code")
  type schemaDefinitionError =
    | @as(0x04_05_00_00) SchemaDefinitionError
    | ...invalidDefinitionError
    | ...duplicateDefinitionError

  @tag("code")
  type transactionTimeoutError =
    | @as(0x04_06_0a_00) TransactionTimeoutError | @as(0x04_06_0a_01) IdleTransactionTimeoutError

  @tag("code")
  type sessionTimeoutError =
    | @as(0x04_06_00_00) SessionTimeoutError
    | @as(0x04_06_01_00) IdleSessionTimeoutError
    | @as(0x04_06_02_00) QueryTimeoutError
    | ...transactionTimeoutError

  @tag("code")
  type queryError =
    | @as(0x04_00_00_00) QueryError
    | @as(0x04_04_00_00) SchemaError
    | ...invalidSyntaxError
    | ...invalidTypeError
    | ...invalidReferenceError
    | ...schemaDefinitionError
    | ...sessionTimeoutError

  @tag("code")
  type invalidValueError =
    | @as(0x05_01_00_00) InvalidValueError
    | @as(0x05_01_00_01) DivisionByZeroError
    | @as(0x05_01_00_02) NumericOutOfRangeError
    | @as(0x05_01_00_03) AccessPolicyError
    | @as(0x05_01_00_04) QueryAssertionError

  @tag("code")
  type integrityError =
    | @as(0x05_02_00_00) IntegrityError
    | @as(0x05_02_00_01) ConstraintViolationError
    | @as(0x05_02_00_02) CardinalityViolationError
    | @as(0x05_02_00_03) MissingRequiredError

  @tag("code")
  type transactionConflictError =
    | @as(0x05_03_01_00) TransactionConflictError
    | @as(0x05_03_01_01) TransactionSerializationError
    | @as(0x05_03_01_02) TransactionDeadlockError

  @tag("code")
  type transactionError = | @as(0x05_03_00_00) TransactionError | ...transactionConflictError

  @tag("code")
  type executionError =
    | @as(0x05_00_00_00) ExecutionError
    | @as(0x05_04_00_00) WatchError
    | ...invalidValueError
    | ...integrityError
    | ...transactionError

  @tag("code")
  type accessError = | @as(0x07_00_00_00) AccessError | @as(0x07_01_00_00) AuthenticationError

  @tag("code")
  type availabilityError =
    | @as(0x08_00_00_00) AvailabilityError | @as(0x08_00_00_01) BackendUnavailableError

  @tag("code")
  type backendError =
    | @as(0x09_00_00_00) BackendError | @as(0x09_00_01_00) UnsupportedBackendFeatureError

  @tag("code")
  type logMessage = | @as(0xf0_00_00_00) LogMessage | @as(0xf0_01_00_00) WarningMessage

  @tag("code")
  type clientConnectionFailedError =
    | @as(0xff_01_01_00) ClientConnectionFailedError
    | @as(0xff_01_01_01) ClientConnectionFailedTemporarilyError

  @tag("code")
  type clientConnectionError =
    | ...clientConnectionFailedError
    | @as(0xff_01_00_00) ClientConnectionError
    | @as(0xff_01_02_00) ClientConnectionTimeoutError
    | @as(0xff_01_03_00) ClientConnectionClosedError

  @tag("code")
  type queryArgumentError =
    | @as(0xff_02_01_00) QueryArgumentError
    | @as(0xff_02_01_01) MissingArgumentError
    | @as(0xff_02_01_02) UnknownArgumentError
    | @as(0xff_02_01_03) InvalidArgumentError

  @tag("code")
  type interfaceError = | @as(0xff_02_00_00) InterfaceError | ...queryArgumentError

  @tag("code")
  type clientError =
    | @as(0xff_00_00_00) ClientError
    | @as(0xff_03_00_00) NoDataError
    | @as(0xff_04_00_00) InternalClientError
    | ...clientConnectionError
    | ...interfaceError

  @tag("code")
  type t =
    | @as(0x01_00_00_00) InternalServerError
    | @as(0x02_00_00_00) UnsupportedFeatureError
    | @as(0x06_00_00_00) ConfigurationError
    | ...queryError
    | ...executionError
    | ...accessError
    | ...availabilityError
    | ...backendError
    | ...logMessage
    | ...clientError
    | ...protocolError

  type edgeDbErrorClass = {code: t}

  type errorFromOperation = EdgeDbError(edgeDbErrorClass) | GenericError(Exn.t)

  type edgeDbError

  @module("edgedb") external edgeDbError: edgeDbError = "EdgeDBError"

  let instanceOf: ('a, 'b) => bool = %raw(`function instanceOf(a, b) {
    return a instanceof b
  }`)

  let fromExn = (exn: Exn.t): errorFromOperation => {
    if exn->instanceOf(edgeDbError) {
      EdgeDbError(Obj.magic(exn))
    } else {
      GenericError(exn)
    }
  }
}

module QueryHelpers = {
  /** Returns all found items as an array. */
  let many = (client, query, ~args=?) => Client.query(client, query, ~args)

  /** Returns a single item, if one was found. */
  let single = async (client, query, ~args=?, ~onError=?) =>
    switch await Client.querySingle(client, query, ~args) {
    | Value(v) => Some(v)
    | Null => None
    | exception Exn.Error(err) =>
      switch onError {
      | None => ()
      | Some(onError) => onError(err->Error.fromExn)
      }
      None
    }

  /** Assumes exactly one item is going to be found, and errors if that's not the case. */
  let singleRequired = async (client, query, ~args=?) =>
    switch await Client.queryRequiredSingle(client, query, ~args) {
    | v => Ok(v)
    | exception Exn.Error(err) => Error(err->Error.fromExn)
    }
}
