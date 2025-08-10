import * as types from './types'
import * as provider from './provider'
import * as utils from './utils'

export class impl implements provider.Provider {
    async convertToProviderRequest(request: Request, baseUrl: string, apiKey: string): Promise<Request> {
        const claudeRequest = (await request.json()) as types.ClaudeRequest
        const qwenRequest = this.convertToQwenRequestBody(claudeRequest)

        const finalUrl = utils.buildUrl(baseUrl, '')

        const headers = new Headers(request.headers)
        headers.set('Authorization', `Bearer ${apiKey}`)
        headers.set('Content-Type', 'application/json')
        headers.delete('x-api-key')

        return new Request(finalUrl, {
            method: 'POST',
            headers,
            body: JSON.stringify(qwenRequest)
        })
    }

    async convertToClaudeResponse(qwenResponse: Response): Promise<Response> {
        if (!qwenResponse.ok) {
            return qwenResponse
        }

        const qwenData = (await qwenResponse.json()) as types.QwenResponse
        const claudeResponse: types.ClaudeResponse = {
            id: utils.generateId(),
            type: 'message',
            role: 'assistant',
            content: []
        }

        if (qwenData.output && qwenData.output.text) {
            claudeResponse.content.push({
                type: 'text',
                text: qwenData.output.text
            })
        }

        claudeResponse.stop_reason = qwenData.output?.finish_reason === 'stop' ? 'end_turn' : 'max_tokens'

        if (qwenData.usage) {
            claudeResponse.usage = {
                input_tokens: qwenData.usage.input_tokens || 0,
                output_tokens: qwenData.usage.output_tokens || 0
            }
        }

        return new Response(JSON.stringify(claudeResponse), {
            status: qwenResponse.status,
            headers: {
                'Content-Type': 'application/json'
            }
        })
    }

    private convertToQwenRequestBody(claudeRequest: types.ClaudeRequest): types.QwenRequest {
        const messages = claudeRequest.messages.map(msg => ({
            role: msg.role,
            content:
                typeof msg.content === 'string'
                    ? msg.content
                    : msg.content.map(c => (c.type === 'text' ? c.text : '')).join('')
        }))

        const qwenRequest: types.QwenRequest = {
            model: this.mapModel(claudeRequest.model),
            input: {
                messages: messages
            },
            parameters: {}
        }

        if (claudeRequest.max_tokens) {
            // Qwen has a max_tokens limit of 8192
            qwenRequest.parameters.max_tokens = Math.min(claudeRequest.max_tokens, 8192)
        }

        if (claudeRequest.temperature !== undefined) {
            qwenRequest.parameters.temperature = claudeRequest.temperature
        }

        return qwenRequest
    }

    private mapModel(claudeModel: string): string {
        const modelMap: { [key: string]: string } = {
            'claude-3-5-sonnet-20241022': 'qwen-max',
            'claude-3-5-sonnet': 'qwen-max',
            'claude-3-haiku': 'qwen-turbo',
            'claude-3-opus': 'qwen-plus'
        }
        return modelMap[claudeModel] || claudeModel
    }
}
