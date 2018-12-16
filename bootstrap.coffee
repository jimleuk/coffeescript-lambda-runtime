http = require 'http'

RUNTIME_PATH = '/2018-06-01/runtime'

{
    AWS_LAMBDA_FUNCTION_NAME,
    AWS_LAMBDA_FUNCTION_VERSION,
    AWS_LAMBDA_FUNCTION_MEMORY_SIZE,
    AWS_LAMBDA_LOG_GROUP_NAME,
    AWS_LAMBDA_LOG_STREAM_NAME,
    LAMBDA_TASK_ROOT,
    _HANDLER,
    AWS_LAMBDA_RUNTIME_API,
} = process.env

[HOST, PORT] = AWS_LAMBDA_RUNTIME_API.split ':'

start = () ->
    try
        handler = getHandler()
    catch e
        await initError e
        return process.exit 1

    try
        await processEvents handler
        return
    catch e
        console.error e
        return process.exit 1

processEvents = (handler) ->
    while true
        { event, context } = await nextInvocation()

        try
            result = await new Promise (resolve) ->
                handler event, context, (err, response) ->
                    throw new Error err if err?
                    resolve response
                    return
                return
        catch e
            await invokeError e, context
            continue

        await invokeResponse result, context
        continue

initError = (err) ->
    postError "#{RUNTIME_PATH}/init/error", err

nextInvocation = () ->
    res = await request {
        path: "#{RUNTIME_PATH}/invocation/next"
    }

    if res.statusCode isnt 200
        throw new Error "Unexpected /invocation/next response: #{JSON.stringify res}"

    if res.headers['lambda-runtime-trace-id']
        process.env._X_AMZN_TRACE_ID = res.headers['lambda-runtime-trace-id']
    else
        delete process.env._X_AMZN_TRACE_ID

    deadlineMs = +res.headers['lambda-runtime-deadline-ms']

    context =
        awsRequestId: res.headers['lambda-runtime-aws-request-id'],
        invokedFunctionArn: res.headers['lambda-runtime-invoked-function-arn'],
        logGroupName: AWS_LAMBDA_LOG_GROUP_NAME,
        logStreamName: AWS_LAMBDA_LOG_STREAM_NAME,
        functionName: AWS_LAMBDA_FUNCTION_NAME,
        functionVersion: AWS_LAMBDA_FUNCTION_VERSION,
        memoryLimitInMB: AWS_LAMBDA_FUNCTION_MEMORY_SIZE,
        getRemainingTimeInMillis: () -> deadlineMs - Date.now(),

    if res.headers['lambda-runtime-client-context']
        context.clientContext = JSON.parse res.headers['lambda-runtime-client-context']

    if res.headers['lambda-runtime-cognito-identity']
        context.identity = JSON.parse res.headers['lambda-runtime-cognito-identity']

    event = JSON.parse res.body

    { event, context }

invokeResponse = (result, context) ->
    res = await request {
        method: 'POST',
        path: "#{RUNTIME_PATH}/invocation/#{context.awsRequestId}/response",
        body: JSON.stringify result,
    }

    if res.statusCode isnt 202
        throw new Error "Unexpected /invocation/response response: #{JSON.stringify res}"

invokeError = (err, context) ->
    postError "#{RUNTIME_PATH}/invocation/#{context.awsRequestId}/error", err
    return

postError = (path, err) ->
    lambdaErr = toLambdaErr err
    res = await request {
        method: 'POST',
        path,
        headers:
            'Content-Type': 'application/json',
            'Lambda-Runtime-Function-Error-Type': lambdaErr.errorType,
        body: JSON.stringify lambdaErr
    }

    if res.statusCode isnt 202
        throw new Error "Unexpected #{path} response: #{JSON.stringify res}"

getHandler = () ->
    appParts = _HANDLER.split '.'

    if appParts.length isnt 2
        throw new Error "Bad handler #{_HANDLER}"

    [modulePath, handlerName] = appParts

    try
        app = require "#{LAMBDA_TASK_ROOT}/#{modulePath}"
    catch e
        if e.code is 'MODULE_NOT_FOUND'
            throw new Error "Unable to import module '#{modulePath}'"
        throw new Error "Unable to import module '#{e.code}'"

    userHandler = app[handlerName]

    if not userHandler?
        throw new Error "Handler '#{handlerName}' missing on module '#{modulePath}'"
    else if typeof userHandler isnt 'function'
        throw new Error "Handler '#{handlerName}' from '#{modulePath}' is not a function"

    userHandler

request = (options) ->
    options.host = HOST
    options.port = PORT

    new Promise (resolve, reject) ->
        req = http.request options, (res) ->
            bufs = []
            res.on 'data', (data) -> bufs.push data
            res.on 'end', () -> resolve {
                statusCode: res.statusCode,
                headers: res.headers,
                body: Buffer.concat(bufs).toString(),
            }
            res.on 'error', reject
            return

        req.on 'error', reject
        req.end options.body
        return

toLambdaErr = ({ name, message, stack }) ->
    {
        errorType: name,
        errorMessage: message,
        stackTrace: if stack then stack.split('\n').slice 1 else '',
    }

start()