class CustomerSuccessBalancingValidate
  MAX_NUMBER_OF_CUSTOMER_SUCCESS = 999
  MAX_NUMBER_OF_COSTUMERS = 999_999
  MAX_ID_OF_CUSTOMER_SUCCESS = 999
  MAX_ID_OF_CUSTOMERS = 999_999
  MAX_CUSTOMER_SUCCESS_SCORE = 9_999
  MAX_CUSTOMERS_SCORE = 99_999
  MAX_AWAY_CUSTOMER_SUCCESS = MAX_NUMBER_OF_CUSTOMER_SUCCESS / 2

  def initialize(customer_success_balancing)
    @customer_success_balancing = customer_success_balancing
  end

  def execute!
    return if [valid_customer_success_size?, valid_customers_size?, valid_customers_id?,
               valid_away_customer_success_size?, valid_customer_success_id?,
               valid_customer_success_score?, valid_customers_score?].all?

    raise ArgumentError
  end

  def valid_customer_success_size?
    size = @customer_success_balancing.customer_success.size

    MAX_NUMBER_OF_CUSTOMER_SUCCESS >= size && size.positive?
  end

  def valid_customers_size?
    size = @customer_success_balancing.customers.size

    MAX_NUMBER_OF_COSTUMERS > size && size.positive?
  end

  def valid_away_customer_success_size?
    size = @customer_success_balancing.away_customer_success.size

    MAX_AWAY_CUSTOMER_SUCCESS >= size
  end

  def valid_customer_success_id?
    min = @customer_success_balancing.customer_success.min_by { |cs| cs[:id] }
    max = @customer_success_balancing.customer_success.max_by { |cs| cs[:id] }

    return false if max.nil? || min.nil?

    MAX_ID_OF_CUSTOMER_SUCCESS >= max[:id].to_i && min[:id].to_i.positive?
  end

  def valid_customers_id?
    min = @customer_success_balancing.customers.min_by { |customer| customer[:id] }
    max = @customer_success_balancing.customers.max_by { |customer| customer[:id] }

    return false if max.nil? || min.nil?

    MAX_ID_OF_CUSTOMERS >= max[:id] && min[:id].positive?
  end

  def valid_customer_success_score?
    min = @customer_success_balancing.customer_success.first
    max = @customer_success_balancing.customer_success.last

    return false if max.nil? || min.nil?

    MAX_CUSTOMER_SUCCESS_SCORE >= max[:score] && min[:score].positive?
  end

  def valid_customers_score?
    customers = @customer_success_balancing.customers.sort_by { |customer| customer[:score] }

    min = customers.first
    max = customers.last

    return false if max.nil? || min.nil?

    MAX_CUSTOMERS_SCORE >= max[:score] && min[:score].positive?
  end
end

class CustomerSuccessBalancingValidateTests < Minitest::Test
  def test_costumer_success_max_size
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores(Array.new(1_000, 1)),
        build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
        [4, 5, 6]
      )
    end
  end

  def test_costumer_success_min_size
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([]),
        build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
        []
      )
    end
  end

  def test_costumers_max_size
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        build_scores(Array.new(1_000_000, 1)),
        []
      )
    end
  end

  def test_costumers_min_size
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        build_scores([]),
        []
      )
    end
  end

  def test_away_costumers_success_max_size
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        build_scores([1, 2, 3]),
        Array.new(500, 1)
      )
    end
  end

  def test_costumers_success_max_id
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        [{ id: 1_000, score: 10 }],
        build_scores([1, 2, 3]),
        []
      )
    end
  end

  def test_costumers_success_min_id
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        [{ id: 0, score: 10 }],
        build_scores([1, 2, 3]),
        []
      )
    end
  end

  def test_costumers_max_id
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        [{ id: 1_000_000, score: 10 }],
        []
      )
    end
  end

  def test_costumers_min_id
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        [{ id: 0, score: 10 }],
        []
      )
    end
  end

  def test_costumer_success_max_score
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        [{ id: 1, score: 10_000 }, { id: 2, score: 10 }],
        build_scores([1, 2, 3]),
        []
      )
    end
  end

  def test_costumer_success_min_score
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 0]),
        build_scores([1, 2, 3]),
        []
      )
    end
  end

  def test_costumers_max_score
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        [{ id: 1, score: 1_000_000 }, { id: 2, score: 1 }],
        []
      )
    end
  end

  def test_costumers_min_score
    assert_raises(ArgumentError) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        [{ id: 1, score: 1_000_000 }, { id: 2, score: 0 }],
        []
      )
    end
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
