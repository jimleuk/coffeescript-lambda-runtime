# CoffeeScript for AWS Lambda

A custom runtime for AWS Lambda to execute functions in CoffeeScript.

> **Note**: This repository is essentially a CoffeeScript port and fork of 
[Node-Custom-Lambda](https://github.com/lambci/node-custom-lambda).

> **New to CoffeeScript?**  
> I recommend starting at https://coffeescript.org/

## How does it work?
`CoffeeScript-lambda-runtime` works by taking care of the compiling and execution of CoffeeScript source code at time of request. This means end-users of the runtime are not required to compile their CoffeeScript code to javascript before uploading their functions to AWS Lambda.
  
Simply write your functions as you would for Node.js and it should just work.
```coffeescript
# feel alive again!
exports.handler = (event, context) ->
    statusCode: 200,
    body:
        JSON.stringify
            message: 'CoffeeScript Serverless v1.0! Your function executed successfully!',
            input: event,
```

alternatively, if you prefer the callback method:
```coffeescript
# feel alive again!
exports.handler = (event, context, callback) ->
    response =
        statusCode: 200,
        body:
            JSON.stringify
                message: 'CoffeeScript Serverless v1.0! Your function executed successfully!',
                input: event,

    callback null, response
```

## Version ARN

Project|CoffeeScript|NodeJS|ARN|
|-|-|-|-|
|v1.1.0|v2.3.2|v8.10.0|arn:aws:lambda:eu-west-2:321742921541:layer:coffeescript:4|

## Building the runtime layer

There are two ways to get started using the coffeescript runtime,
  1. build & upload your own copy (recommended)
  2. or use the ARN supplied above if you just want to give it a try

To start building your own, simply do the following once you have cloned the repo:

```
# Make sure you have a copy of coffeescript/cake installed globally
> npm install -g coffeescript

# Install required dependencies
> npm install

# go into the project root and type `cake build`
> cake build

===========================================================
runtime:        coffeescript-lambda-runtime_1.0.0
CoffeeScript:   v2.3.2
NodeJs:         v8.10.0
===========================================================
building image... ok
packaging image... ok
build completed successfully!
    output:     build/coffeescript-lambda-runtime_1.0.0.zip
```

## Publishing your runtime layer

Once you have your build (ie. `build/coffeescript-lambda-runtime_1.0.0.zip`),
simply upload to your aws account to make it available to your functions.

Simpliest way to do this is to use the aws console via `aws lambda > layers > create layer`.

Alternatively you can use the `cake publish` task to achieve the same thing. Note that `cake publish` uses the aws-cli so requires that your aws credentials are available before the task is executed.

For more info, please read the [official documentation of AWS Lambda Layers](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html).

## Credits

[Node-custom-lambda](https://github.com/lambci/node-custom-lambda) by [@mhart](https://github.com/mhart) - of which this project is "forked" from

## FAQs

> **Note**: This runtime does not include the AWS-SDK
<details>
<summary>Is this runtime practical?</summary>
<p>
If you're not too fussed about cold start times then yes! Just remember that everytime a container starts it has to compile coffeescript source code before it runs, which may or may not be slow depending on given compute power. A warm container will be quite fast.
</p>
</details>

<details>
<summary>Can I write with all modern CoffeeScript syntax or only those compatible with NodeJs?</summary>
<p>
Under the hood, the runtime transpiles all CoffeeScript code using <a href="https://babeljs.io/" rel="noopener">babel</a> which is configured to best match the NodeJs environment. This will ensure that end-users can confidently use modern ES6+ syntax without worrying about polyfills.
</p>
</details>

