local M = {}
local curl = require("plenary.curl")

local function find_function_end()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local current_node = ts_utils.get_node_at_cursor()
	while
		current_node and (current_node:type() ~= "function_declaration" and current_node:type() ~= "method_declaration")
	do
		current_node = current_node:parent()
	end
	if current_node then
		local end_row = current_node:end_()
		return end_row + 1
	end
	return nil
end

local function get_api_key()
	local api_key = os.getenv("ANTHROPIC_API_KEY")
	if not api_key then
		vim.notify("ANTHROPIC environment variable not set!", vim.log.levels.ERROR)
	end
	return api_key
end

local function get_current_function()
	local start_line = nil
	local end_line = nil
	local buf = vim.api.nvim_get_current_buf()
	local cur_line = vim.api.nvim_win_get_cursor(0)[1] -- current cursor position is the start of the function
	start_line = cur_line
	end_line = find_function_end()
	local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
	return lines, start_line, end_line
end

local function request_swagger_docs(handler_code, callback)
	local api_key = get_api_key()
	if not api_key then
		return
	end

	local prompt = [[
You are a swagger generater for echo-swagger golang.Dont spit out any other additional info , just the required commented swagger docs. No explanation ,no disclaimer, no additional info. Just the swagger docs.
<Example>
```go
func (handler accountHandler) Create(ctx echo.Context) error {

	var accountView view.AccountView
	err := ctx.Bind(&accountView)
	if err != nil {
		logrus.Error("error occurred: ", err.Error())
		return api.BadRequestResponse(ctx, "Bad Request.")
	}
	err = ctx.Validate(accountView)

	if err != nil {
		result := view.TranslateError(err)
		return api.ValidationErrorResponse(ctx, result)
	}
	account, err := handler.accountService.CreateAccount(ctx, accountView)
	if err != nil {
		return api.ErrorResponse(ctx, err)
	}
	return api.SuccessResponse(ctx, account)
}

```
For the above code snippet , the response should be :
// Create Account godoc
//
//	@Summary		Creates an account
//	@Description	creates an account with given data
//	@Tags			accounts
//	@Accept			json
//	@Produce		json
//
//	@Security		namespace
//	@Security		Bearer
//	@Param			request	body		view.AccountView	true	"request body"
//
//	@Success		200		{object}	api.Response{data=domain.Account}
//	@Failure		400		{object}	api.Response
//	@Failure		404		{object}	api.Response
//	@Failure		500		{object}	api.Response
//	@Router			/accounts [post]
</Example>

]]

	local user_prompt = [[
    Handler Function:
    ]] .. handler_code .. [[
    Generate commented swagger docs for this above handler function so echo-swagger can genrate swagger.dont include ``` go in the response. Just the comments.`
  ]]

	local request_body = {
		model = "claude-3-5-sonnet-20241022",
		max_tokens = 2000,
		messages = {
			{ role = "assistant", content = prompt },
			{ role = "user", content = user_prompt },
		},
		temperature = 0,
	}

	curl.post("https://api.anthropic.com/v1/messages", {
		headers = {
			["x-api-key"] = api_key,
			["anthropic-version"] = "2023-06-01",
			["Content-Type"] = "application/json",
		},
		body = vim.fn.json_encode(request_body),
		callback = function(response)
			local json_resp = vim.json.decode(response.body)
			local completion = nil
			if json_resp and json_resp.content and json_resp.content[1] and json_resp.content[1].text then
				completion = json_resp.content[1].text
			end

			if completion then
				vim.schedule(function()
					callback(completion)
				end)
			else
				vim.schedule(function()
					vim.notify("No completion received.", vim.log.levels.ERROR)
				end)
			end
		end,
	})
end

local function insert_swagger_docs(swagger_docs, start_line)
	local buf = vim.api.nvim_get_current_buf()
	local doc_lines = {}
	for line in string.gmatch(swagger_docs, "[^\r\n]+") do
		table.insert(doc_lines, line)
	end
	vim.api.nvim_buf_set_lines(buf, start_line - 1, start_line - 1, false, doc_lines)
	vim.notify("Swagger documentation inserted.", vim.log.levels.INFO)
end

function M.generate_swagger_docs()
	print("Inserting....")
	local handler_lines, start_line = get_current_function()
	if not handler_lines then
		return
	end
	local handler_code = table.concat(handler_lines, "\n")

	request_swagger_docs(handler_code, function(swagger)
		insert_swagger_docs(swagger, start_line)
	end)
end

return M
