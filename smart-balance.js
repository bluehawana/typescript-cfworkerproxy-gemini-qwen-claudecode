// Smart Balance - Inspired by one-balance project
// Intelligent load balancing across multiple AI providers

addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
})

// Provider configurations with health status
const PROVIDERS = {
    anyrouter: {
        name: 'AnyRouter',
        baseUrl: 'https://anyrouter.top',
        headers: (apiKey) => ({
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        }),
        healthy: true,
        lastCheck: 0,
        failCount: 0,
        cost: 'free'
    },
    gemini: {
        name: 'Google Gemini',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent',
        headers: (apiKey) => ({
            'x-goog-api-key': apiKey,
            'Content-Type': 'application/json'
        }),
        transform: claudeToGemini,
        transformResponse: geminiToClaude,
        healthy: true,
        lastCheck: 0,
        failCount: 0,
        cost: 'free'
    },
    qwen: {
        name: 'Alibaba Qwen',
        baseUrl: 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation',
        headers: (apiKey) => ({
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        }),
        transform: claudeToQwen,
        transformResponse: qwenToClaude,
        healthy: true,
        lastCheck: 0,
        failCount: 0,
        cost: 'cheap'
    }
}

// API Keys from environment
const API_KEYS = {
    anyrouter: 'ANYROUTER_API_KEY',
    gemini: 'GEMINI_API_KEY',
    qwen: 'QWEN_API_KEY'
}

async function handleRequest(request) {
    if (request.method !== 'POST') {
        return new Response('Method Not Allowed', { status: 405 })
    }

    try {
        // Get API keys from headers or environment
        const apiKeys = {}
        for (const [provider, envVar] of Object.entries(API_KEYS)) {
            apiKeys[provider] = request.headers.get(`x-${provider}-key`) || 
                               request.headers.get('x-api-key') ||
                               request.headers.get('authorization')?.replace('Bearer ', '')
        }

        const body = await request.json()
        
        // Get preferred provider from URL path or header
        const url = new URL(request.url)
        const preferredProvider = url.pathname.split('/')[1] || 
                                request.headers.get('x-provider') || 
                                'auto'

        // Try providers in order of preference
        const providers = getProviderOrder(preferredProvider)
        
        for (const providerName of providers) {
            const provider = PROVIDERS[providerName]
            const apiKey = apiKeys[providerName]
            
            if (!apiKey || !provider.healthy) {
                continue
            }

            try {
                const result = await callProvider(providerName, provider, apiKey, body)
                if (result) {
                    // Mark provider as healthy
                    provider.failCount = 0
                    provider.healthy = true
                    return result
                }
            } catch (error) {
                console.error(`Provider ${providerName} failed:`, error)
                // Mark provider as unhealthy after multiple failures
                provider.failCount++
                if (provider.failCount >= 3) {
                    provider.healthy = false
                    provider.lastCheck = Date.now()
                }
                continue
            }
        }

        return new Response('All providers unavailable', { status: 503 })
        
    } catch (error) {
        console.error('Request processing error:', error)
        return new Response('Bad Request: ' + error.message, { status: 400 })
    }
}

function getProviderOrder(preferred) {
    if (preferred === 'auto') {
        // Return providers sorted by cost and health
        return Object.keys(PROVIDERS)
            .filter(name => PROVIDERS[name].healthy)
            .sort((a, b) => {
                const costOrder = { free: 0, cheap: 1, paid: 2 }
                return costOrder[PROVIDERS[a].cost] - costOrder[PROVIDERS[b].cost]
            })
    }
    
    if (PROVIDERS[preferred]) {
        // Try preferred first, then fallback to others
        const others = Object.keys(PROVIDERS).filter(name => name !== preferred)
        return [preferred, ...others]
    }
    
    return Object.keys(PROVIDERS)
}

async function callProvider(name, provider, apiKey, body) {
    // Transform request if needed
    const requestBody = provider.transform ? provider.transform(body) : body
    
    const response = await fetch(provider.baseUrl, {
        method: 'POST',
        headers: provider.headers(apiKey),
        body: JSON.stringify(requestBody)
    })

    if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    const responseData = await response.json()
    
    // Transform response if needed
    const finalResponse = provider.transformResponse ? 
        provider.transformResponse(responseData) : responseData

    return new Response(JSON.stringify(finalResponse), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
    })
}

// Transform functions (simplified versions)
function claudeToGemini(claudeBody) {
    return {
        contents: claudeBody.messages.map(msg => ({
            role: msg.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: msg.content }]
        }))
    }
}

function geminiToClaude(geminiResponse) {
    const candidate = geminiResponse.candidates[0]
    const content = candidate.content.parts.map(part => part.text).join('')
    
    return {
        id: `msg_${Date.now()}`,
        type: 'message',
        role: 'assistant',
        content: [{ type: 'text', text: content }],
        model: 'claude-3-5-sonnet-20241022'
    }
}

function claudeToQwen(claudeBody) {
    return {
        model: 'qwen-max',
        messages: claudeBody.messages.map(msg => ({
            role: msg.role,
            content: msg.content
        }))
    }
}

function qwenToClaude(qwenResponse) {
    return {
        id: `msg_${Date.now()}`,
        type: 'message',
        role: 'assistant',
        content: [{ type: 'text', text: qwenResponse.output.text }],
        model: 'claude-3-5-sonnet-20241022'
    }
}