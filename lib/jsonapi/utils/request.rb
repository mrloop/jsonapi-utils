module JSONAPI::Utils
  module Request
    # Setup and check request before action gets actually evaluated.
    #
    # @api public
    def jsonapi_request_handling
      setup_request
      check_request
    end

    # Instantiate the request object.
    #
    # @return [JSONAPI::RequestParser]
    #
    # @api public
    def setup_request
      @request ||= JSONAPI::RequestParser.new(
        params,
        context: context,
        key_formatter: key_formatter,
        server_error_callbacks: (self.class.server_error_callbacks || [])
      )
    end

    # Render an error response if the parsed request got any error.
    #
    # @api public
    def check_request
      @request.errors.blank? || jsonapi_render_errors(json: @request)
    end

    # Helper to get params for the main resource.
    #
    # @return [Hash]
    #
    # @api public
    def resource_params
      build_params_for(:resource)
    end

    # Helper to get params for relationship params.
    #
    # @return [Hash]
    #
    # @api public
    def relationship_params
      build_params_for(:relationship)
    end

    private

    # Extract params from request and build a Hash with params
    # for either the main resource or relationships.
    #
    # @return [Hash]
    #
    # @api private
    def build_params_for(param_type)
      return {} if @request.operations.empty?

      keys = %i(attributes to_one to_many)
      operation = @request.operations.find { |e| e.options[:data].keys & keys == keys }

      if operation.nil?
        {}
      elsif param_type == :relationship
        operation.options[:data].values_at(:to_one, :to_many).compact.reduce(&:merge)
      else
        operation.options[:data][:attributes]
      end
    end
  end
end
