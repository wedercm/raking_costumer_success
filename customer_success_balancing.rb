require 'minitest/autorun'
require 'timeout'
require_relative 'customer_success_balancing_validate'

class CustomerSuccessBalancing
  attr_reader :customer_success, :customers, :away_customer_success

  TIE_CUESTOMER_SUCCESS_ID = 0

  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success.sort_by { |cs| cs[:score] }
    @customers = customers
    @away_customer_success = away_customer_success

    validate_arguments!
  end

  # Returns the ID of the customer success with most customers
  def execute
    top_customer_success = [{ id: 0, total_customers: -1 }, { id: 0, total_customers: -1 }]

    @customers.each do |customer|
      customer_success = fetch_customer_responsible(customer)

      next if away_customer_success?(customer_success)

      top_customer_success = recalc_top_customer_success(top_customer_success, customer_success)
    end

    closest_customer_success_id(top_customer_success)
  end

  private

  def fetch_customer_responsible(customer)
    @customer_success.bsearch do |customer_success|
      (customer_success[:score] - customer[:score]) >= 0
    end
  end

  def away_customer_success?(customer_success)
    customer_success.nil? || @away_customer_success.include?(customer_success[:id])
  end

  def recalc_top_customer_success(top_customer_success, customer_success)
    customer_success[:total_customers] = customer_success[:total_customers].to_i.succ

    top_customer_success.map do |cs|
      if customer_success[:total_customers] > cs[:total_customers]
        result = customer_success.dup
        customer_success = cs.dup

        result
      else
        cs
      end
    end
  end

  def closest_customer_success_id(top_customer_success)
    if top_customer_success[0][:total_customers] == top_customer_success[1][:total_customers]
      TIE_CUESTOMER_SUCCESS_ID
    else
      top_customer_success[0][:id]
    end
  end

  def validate_arguments!
    CustomerSuccessBalancingValidate.new(self).execute!
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10_000, 998)),
      [999]
    )
    result = Timeout.timeout(1) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
