# Test that global requires work
import aws4 from 'aws4'

exports.handlerCallback = (event, context, callback) ->
    response =
        statusCode: 200,
        body:
            JSON.stringify
                message: 'CoffeeScript Serverless v1.0! Your function executed successfully!',
                input: event,

    callback null, response

exports.handlerAsync = (event, context) ->
    statusCode: 200,
    body:
        JSON.stringify
            message: 'CoffeeScript Serverless v1.0! Your function executed successfully!',
            input: event,
