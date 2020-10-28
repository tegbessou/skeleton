<?php

namespace App\Tests\Util;

use App\Util\Calculator;
use PHPUnit\Framework\TestCase;

class CalculatorTest extends TestCase
{
    public function testAdd()
    {
        $calculator = new Calculator();
        $result = $calculator->add(50, 24);

        // assert that your calculator added the numbers correctly!
        $this->assertEquals(74, $result);
    }
}
