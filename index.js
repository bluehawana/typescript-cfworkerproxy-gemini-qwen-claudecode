addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
})

// 简单限流示范：允许每秒最多5次请求（可用 Durable Objects 优化）
const RATE_LIMIT = 5
let requestsInCurrentSecond = 0
let currentSecond = Math.floor(Date.now() / 1000)

// 支持的提供商列表
const SUPPORTED_PROVIDERS = ['anthropic', 'gemini', 'openai', 'qwen', 'anyrouter', 'cerebras']

// 模型名称映射
const MODEL_MAPPINGS = {
    gemini: {
        'claude-3-5-sonnet-20241022': 'gemini-2.0-flash-exp',
        'claude-3-5-sonnet': 'gemini-2.0-flash-exp',
        'claude-3-haiku': 'gemini-1.5-flash',
        'claude-3-opus': 'gemini-1.5-pro'
    },
    openai: {
        'claude-3-5-sonnet-20241022': 'gpt-4o',
        'claude-3-5-sonnet': 'gpt-4o',
        'claude-3-haiku': 'gpt-4o-mini',
        'claude-3-opus': 'gpt-4'
    },
    qwen: {
        'claude-3-5-sonnet-20241022': 'qwen-max',
        'claude-3-5-sonnet': 'qwen-max',
        'claude-3-haiku': 'qwen-turbo',
        'claude-3-opus': 'qwen-plus'
    },
    cerebras: {
        'claude-3-5-sonnet-20241022': 'llama3.1-70b',
        'claude-3-5-sonnet': 'llama3.1-70b',
        'claude-3-haiku': 'llama3.1-8b',
        'claude-3-opus': 'llama3.1-70b'
    }
}

async function handleRequest(request) {
    const now = Math.floor(Date.now() / 1000)
    if (now !== currentSecond) {
        currentSecond = now
        requestsInCurrentSecond = 0
    }

    if (requestsInCurrentSecond >= RATE_LIMIT) {
        return new Response('Rate limit exceeded', { status: 429 })
    }
    requestsInCurrentSecond++

    try {
        const url = new URL(request.url)

        // Add version endpoint for debugging (allow GET)
        if (url.pathname === '/version' || url.pathname === '/health') {
            return new Response(JSON.stringify({
                version: '2.0.0',
                timestamp: new Date().toISOString(),
                status: 'ok',
                features: ['multi-header-auth', 'debug-logging'],
                method: request.method
            }), {
                headers: { 'Content-Type': 'application/json' }
            })
        }

        // Only allow POST requests for API endpoints
        if (request.method !== 'POST') {
            return new Response('Method Not Allowed', { status: 405 })
        }

        // URL格式：/{type}/{provider_url_with_version}/v1/messages
        // 举例 /gemini/https://generativelanguage.googleapis.com/v1beta/v1/messages
        const pathParts = url.pathname.split('/')
        // ['', 'gemini', 'https:', '', 'generativelanguage.googleapis.com', 'v1beta', 'v1', 'messages']

        if (pathParts.length < 3) {
            return new Response('Bad Request: missing provider type and target URL', { status: 400 })
        }

        const type = pathParts[1] // e.g. 'gemini'

        // Debug logging
        console.log('URL pathname:', url.pathname)
        console.log('Path parts:', pathParts)
        console.log('Detected type:', type)

        if (!SUPPORTED_PROVIDERS.includes(type)) {
            return new Response(
                `Unsupported provider: "${type}". Supported: ${SUPPORTED_PROVIDERS.join(', ')}. Full path: ${url.pathname}`,
                { status: 400 }
            )
        }

        // 重建目标URL - 从第三个部分开始重新组合
        const targetParts = pathParts.slice(2)
        let providerUrl = targetParts.join('/')

        // 确保URL以https://开头
        if (!providerUrl.startsWith('https://')) {
            providerUrl = 'https://' + providerUrl
        }

        // 获取API key - 支持多种头格式
        let apiKey = request.headers.get('x-api-key')
        
        // 如果没有x-api-key，尝试从Authorization头获取
        if (!apiKey) {
            const authHeader = request.headers.get('authorization')
            if (authHeader && authHeader.startsWith('Bearer ')) {
                apiKey = authHeader.substring(7) // 移除 "Bearer " 前缀
            }
        }
        
        // 如果没有x-api-key，尝试从anthropic-api-key头获取
        if (!apiKey) {
            apiKey = request.headers.get('anthropic-api-key')
        }
        
        if (!apiKey) {
            return new Response('Missing API key (x-api-key, Authorization Bearer, or anthropic-api-key header)', { status: 401 })
        }

        // 请求体JSON
        const body = await request.json()

        // 根据提供商类型处理请求
        let processedBody, targetUrl, headers

        switch (type) {
            case 'anthropic':
                // 直接转发 Anthropic 请求
                processedBody = body
                targetUrl = providerUrl
                headers = {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${apiKey}`,
                    'anthropic-version': '2023-06-01'
                }
                break

            case 'anyrouter':
                // AnyRouter 直接转发 Claude 格式
                processedBody = body
                targetUrl = providerUrl
                headers = {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${apiKey}`,
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'application/json, text/plain, */*',
                    'Accept-Language': 'en-US,en;q=0.9',
                    'Accept-Encoding': 'gzip, deflate, br',
                    'Origin': 'https://anyrouter.top',
                    'Referer': 'https://anyrouter.top/',
                    'Sec-Ch-Ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
                    'Sec-Ch-Ua-Mobile': '?0',
                    'Sec-Ch-Ua-Platform': '"macOS"',
                    'Sec-Fetch-Dest': 'empty',
                    'Sec-Fetch-Mode': 'cors',
                    'Sec-Fetch-Site': 'same-origin'
                }
                break

            case 'gemini':
                // 转换为 Gemini 格式
                const geminiBody = claudeToGemini(body)
                processedBody = geminiBody
                targetUrl = providerUrl
                headers = {
                    'Content-Type': 'application/json',
                    'x-goog-api-key': apiKey
                }
                break

            case 'openai':
                // 转换为 OpenAI 格式
                const openaiBody = claudeToOpenAI(body)
                processedBody = openaiBody
                targetUrl = providerUrl
                headers = {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${apiKey}`
                }
                break

            case 'qwen':
                // 转换为 Qwen 格式
                const qwenBody = claudeToQwen(body)
                processedBody = qwenBody
                targetUrl = providerUrl
                headers = {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${apiKey}`
                }
                break

            case 'cerebras':
                // 转换为 Cerebras 格式 (OpenAI 兼容)
                const cerebrasBody = claudeToOpenAI(body)
                processedBody = cerebrasBody
                targetUrl = providerUrl
                headers = {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${apiKey}`
                }
                break

            default:
                return new Response(`Provider ${type} not implemented`, { status: 501 })
        }

        // 构造转发请求
        const fetchOptions = {
            method: request.method,
            headers: headers,
            body: JSON.stringify(processedBody)
        }

        // 简单重试机制，最多3次
        for (let i = 0; i < 3; i++) {
            try {
                const resp = await fetch(targetUrl, fetchOptions)

                if (!resp.ok) {
                    if (resp.status >= 500) {
                        // 服务端错误，重试
                        await new Promise(r => setTimeout(r, 500 * (i + 1)))
                        continue
                    } else {
                        // 客户端错误不重试，返回详细错误信息
                        const errorBody = await resp.text()
                        console.error(`Provider ${type} error ${resp.status}:`, errorBody)
                        return new Response(
                            JSON.stringify({
                                error: {
                                    type: 'provider_error',
                                    message: `Provider ${type} returned ${resp.status}: ${resp.statusText}`,
                                    details: errorBody,
                                    provider: type,
                                    target_url: targetUrl
                                }
                            }),
                            {
                                status: resp.status,
                                statusText: resp.statusText,
                                headers: { 'Content-Type': 'application/json' }
                            }
                        )
                    }
                }

                // 成功响应，根据提供商转换回 Claude 格式
                if (type === 'anthropic' || type === 'anyrouter') {
                    // 直接返回
                    return resp
                } else {
                    // 需要转换格式
                    const responseBody = await resp.json()
                    let claudeResponse

                    switch (type) {
                        case 'gemini':
                            claudeResponse = geminiToClaude(responseBody)
                            break
                        case 'openai':
                            claudeResponse = openaiToClaude(responseBody)
                            break
                        case 'qwen':
                            claudeResponse = qwenToClaude(responseBody)
                            break
                        case 'cerebras':
                            claudeResponse = openaiToClaude(responseBody)
                            break
                    }

                    return new Response(JSON.stringify(claudeResponse), {
                        status: 200,
                        headers: { 'Content-Type': 'application/json' }
                    })
                }
            } catch (e) {
                // 网络错误重试
                console.error(`Attempt ${i + 1} failed:`, e.message)
                if (i === 2) {
                    return new Response(`Network error after 3 attempts: ${e.message}`, { status: 503 })
                }
                await new Promise(r => setTimeout(r, 500 * (i + 1)))
            }
        }

        return new Response('Upstream service unavailable', { status: 503 })
    } catch (e) {
        console.error('Request processing error:', e)
        return new Response('Bad Request: ' + e.message, { status: 400 })
    }
}

// ===== 格式转换函数 =====

// Claude 转 Gemini 格式
function claudeToGemini(claudeBody) {
    const contents = claudeBody.messages.map(msg => ({
        role: msg.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: msg.content }]
    }))

    const geminiBody = {
        contents: contents,
        generationConfig: {}
    }

    if (claudeBody.max_tokens) {
        geminiBody.generationConfig.maxOutputTokens = claudeBody.max_tokens
    }
    if (claudeBody.temperature !== undefined) {
        geminiBody.generationConfig.temperature = claudeBody.temperature
    }

    return geminiBody
}

// Gemini 转 Claude 格式
function geminiToClaude(geminiResponse) {
    if (!geminiResponse.candidates || geminiResponse.candidates.length === 0) {
        throw new Error('No candidates in Gemini response')
    }

    const candidate = geminiResponse.candidates[0]
    const content = candidate.content.parts.map(part => part.text).join('')

    return {
        id: `msg_${Date.now()}`,
        type: 'message',
        role: 'assistant',
        content: [
            {
                type: 'text',
                text: content
            }
        ],
        model: 'claude-3-5-sonnet-20241022',
        stop_reason: candidate.finishReason === 'STOP' ? 'end_turn' : 'max_tokens',
        stop_sequence: null,
        usage: {
            input_tokens: geminiResponse.usageMetadata?.promptTokenCount || 0,
            output_tokens: geminiResponse.usageMetadata?.candidatesTokenCount || 0
        }
    }
}

// Claude 转 OpenAI 格式
function claudeToOpenAI(claudeBody) {
    const model = MODEL_MAPPINGS.openai[claudeBody.model] || claudeBody.model

    const openaiBody = {
        model: model,
        messages: claudeBody.messages.map(msg => ({
            role: msg.role,
            content: msg.content
        }))
    }

    if (claudeBody.max_tokens) {
        openaiBody.max_tokens = claudeBody.max_tokens
    }
    if (claudeBody.temperature !== undefined) {
        openaiBody.temperature = claudeBody.temperature
    }
    if (claudeBody.stream) {
        openaiBody.stream = claudeBody.stream
    }

    return openaiBody
}

// OpenAI 转 Claude 格式
function openaiToClaude(openaiResponse) {
    if (!openaiResponse.choices || openaiResponse.choices.length === 0) {
        throw new Error('No choices in OpenAI response')
    }

    const choice = openaiResponse.choices[0]
    const content = choice.message.content

    return {
        id: openaiResponse.id || `msg_${Date.now()}`,
        type: 'message',
        role: 'assistant',
        content: [
            {
                type: 'text',
                text: content
            }
        ],
        model: 'claude-3-5-sonnet-20241022',
        stop_reason: choice.finish_reason === 'stop' ? 'end_turn' : 'max_tokens',
        stop_sequence: null,
        usage: {
            input_tokens: openaiResponse.usage?.prompt_tokens || 0,
            output_tokens: openaiResponse.usage?.completion_tokens || 0
        }
    }
}

// Claude 转 Qwen 格式
function claudeToQwen(claudeBody) {
    const model = MODEL_MAPPINGS.qwen[claudeBody.model] || claudeBody.model

    const qwenBody = {
        model: model,
        messages: claudeBody.messages.map(msg => ({
            role: msg.role,
            content: msg.content
        }))
    }

    if (claudeBody.max_tokens) {
        qwenBody.max_tokens = claudeBody.max_tokens
    }
    if (claudeBody.temperature !== undefined) {
        qwenBody.temperature = claudeBody.temperature
    }
    if (claudeBody.stream) {
        qwenBody.stream = claudeBody.stream
    }

    return qwenBody
}

// Qwen 转 Claude 格式
function qwenToClaude(qwenResponse) {
    if (!qwenResponse.choices || qwenResponse.choices.length === 0) {
        throw new Error('No choices in Qwen response')
    }

    const choice = qwenResponse.choices[0]
    const content = choice.message.content

    return {
        id: qwenResponse.id || `msg_${Date.now()}`,
        type: 'message',
        role: 'assistant',
        content: [
            {
                type: 'text',
                text: content
            }
        ],
        model: 'claude-3-5-sonnet-20241022',
        stop_reason: choice.finish_reason === 'stop' ? 'end_turn' : 'max_tokens',
        stop_sequence: null,
        usage: {
            input_tokens: qwenResponse.usage?.prompt_tokens || 0,
            output_tokens: qwenResponse.usage?.completion_tokens || 0
        }
    }
}
