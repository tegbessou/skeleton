<?php

declare(strict_types=1);

namespace App\Tests\Behat;

use Behat\Behat\Hook\Scope\AfterStepScope;
use Behat\Behat\Hook\Scope\BeforeScenarioScope;
use Behat\Mink\Driver\Selenium2Driver;
use Behat\MinkExtension\Context\RawMinkContext;
use Behat\Testwork\Tester\Result\TestResult;
use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\HttpKernel\KernelInterface;

class ErrorHandlerContext extends RawMinkContext
{
    public const LOCAL_DOMAIN = 'https://skeleton.docker';

    /**
     * @var KernelInterface
     */
    private $kernel;

    /** @var string Scenario Information for error output */
    private $scenarioData;

    /** @var string The local domain for viewing screenshot errors */
    private $localDomain;

    public function __construct(KernelInterface $kernel)
    {
        $this->localDomain = self::LOCAL_DOMAIN;
        $this->kernel = $kernel;
    }

    /**
     * @BeforeSuite
     */
    public static function clean()
    {
        $pathDir = __DIR__.'/../../public/behat_trace';
        $filesystem = new Filesystem();

        if (!$filesystem->exists($pathDir)) {
            $filesystem->mkdir($pathDir);
        }

        if ($filesystem->exists($pathDir.'/html')) {
            $filesystem->remove($pathDir.'/html');
        }

        if ($filesystem->exists($pathDir.'/png')) {
            $filesystem->remove($pathDir.'/png');
        }
    }

    /**
     * Checks if we should look for errors.
     *
     * @BeforeScenario
     */
    public function prepare(BeforeScenarioScope $scope)
    {
        if (null === $this->getMink()) {
            return;
        }

        if (!$this->isSelenium()) {
            return;
        }

        // no need to do anything if this is an empty scenario
        if (!$scope->getScenario()->hasSteps() && !$scope->getFeature()->hasBackground()) {
            return;
        }

        $this->scenarioData = basename($scope->getFeature()->getFile()).'.'.$scope->getScenario()->getLine();
    }

    /**
     * @Then /^I take a screenshot$/
     */
    public function takeScreenShot()
    {
        $this->dumpScreenShot();
    }

    /**
     * Pauses the scenario until the user presses a key. Useful when debugging a scenario.
     *
     * @Then I put a breakpoint
     */
    public function iPutABreakpoint()
    {
        fwrite(STDOUT, "\033[s    \033[93m[Breakpoint] Press \033[1;93m[RETURN]\033[0;93m to continue...\033[0m");
        while (fgets(STDIN, 1024) == '') {
        }
        fwrite(STDOUT, "\033[u");
    }

    /**
     * @Then /^I take a html dump/
     */
    public function takeHTMLDump()
    {
        $this->dumpHtml();
    }

    /**
     * Prints debug info after a failed step with Selenium
     * Like screenshots of current errors or javascript errors.
     *
     * @AfterStep
     */
    public function handleError(AfterStepScope $scope)
    {
        if (!$this->isError($scope)) {
            return;
        }
        fwrite(STDOUT, PHP_EOL.$scope->getTestResult()->hasException() ? $scope->getTestResult()->getException()->getMessage() : ''.PHP_EOL);

        if ($this->isSelenium()) {
            $this->dumpScreenShot();
        } else {
            $this->dumpHtml();
        }
    }

    private function isError(AfterStepScope $scope): bool
    {
        return TestResult::FAILED === $scope->getTestResult()->getResultCode();
    }

    private function isSelenium(): bool
    {
        return $this->getSession()->getDriver() instanceof Selenium2Driver;
    }

    /**
     * Take a screenshot
     * Put the screen(s) in web/behat_trace/screen/{x}.png
     * The path for display the screen is on the console log based on $localDomain.
     */
    private function dumpScreenShot()
    {
        $screen = $this->getSession()->getDriver()->getScreenshot();
        $this->dumpContentError($screen);
    }

    /**
     * Dump the current html when an error occured
     * Put the html in web/behat_trace/html/{x}.html
     * The path for display the html is on the console log based on $localDomain.
     */
    private function dumpHtml()
    {
        $html = $this->getSession()->getPage()->getContent();
        $this->dumpContentError($html);
    }

    private function dumpContentError($content)
    {
        $type = $this->isSelenium() ? 'png' : 'html';
        $filename = sprintf('%s.%s', md5(uniqid((string) mt_rand(), true)), $type);

        $basePath = $this->kernel->getProjectDir().'/public/';
        $webPath = 'behat_trace/'.$type;

        $path = $basePath.$webPath;

        if (!is_dir($path) && !@mkdir($path) && !is_dir($path)) {
            throw new \RuntimeException(sprintf('Could not create folder "%s"...', $path));
        }

        file_put_contents($path.'/'.$filename, $content);

        fwrite(STDOUT, sprintf('Preview: %s/%s/%s', $this->localDomain, $webPath, $filename).PHP_EOL);
    }
}
