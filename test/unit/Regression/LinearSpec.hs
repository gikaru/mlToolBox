module Regression.LinearSpec where

import qualified Data.ByteString.Lazy as LB (readFile)
import Data.Csv (HasHeader(NoHeader), decode)
import Data.Either (fromRight)
import qualified Data.Vector as V (empty, toList)
import System.Directory (getCurrentDirectory)
import System.FilePath.Posix ((</>))
import Test.Tasty (TestTree)
import Test.Tasty (testGroup)
import Test.Tasty.Hspec (Spec, describe, it, shouldSatisfy, testSpecs)

import ToolBox
  ( Matrix
  , R
  , Vector
  , addOnesColumn
  , computeCostFunction
  , featureNormalize
  , splitMatrixOfSamples
  , toListMatrix
  , toMatrix
  , toVector
  )

tests :: IO TestTree
tests = do
  curDir <- getCurrentDirectory
  let dataDir = curDir </> "testData"
  (linearRegressionMatrix, normalizedLrMatrix, linearRegressionValues) <-
    readLinearRegressionSample dataDir
  specs <-
    concat <$>
    mapM
      testSpecs
      [ costFunctionSpec linearRegressionMatrix linearRegressionValues
      , featureNormalizeSpec linearRegressionMatrix normalizedLrMatrix
      ]
  return $
    testGroup "LinearRegression" [testGroup "Linear Regression specs" specs]

-- Specs
costFunctionSpec :: Matrix R -> Vector R -> Spec
costFunctionSpec features values =
  describe "computeCostFunction" $ do
    it "should compute correctly for theta vector [0, 0, 0]" $ do
      let r = computeCostFunction features values (toVector [0, 0, 0])
          expectedValue = 65591548106.45744
      r `shouldSatisfy` doubleEq expectedValue
    it "should compute correctly for theta vector [25, 26, 27]" $ do
      let r = computeCostFunction features values (toVector [25, 26, 27])
          expectedValue = 47251185844.64893
      r `shouldSatisfy` doubleEq expectedValue
    it "should compute correctly for theta vector [1500, 227, 230]" $ do
      let r = computeCostFunction features values (toVector [1500, 227, 230])
          expectedValue = 11433546085.01064
      r `shouldSatisfy` doubleEq expectedValue
    it "should compute correctly for theta vector [-15.03, -27.123, -59.675]" $ do
      let r =
            computeCostFunction
              features
              values
              (toVector [-15.03, -27.123, -59.675])
          expectedValue = 88102482793.02190
      r `shouldSatisfy` doubleEq expectedValue

featureNormalizeSpec :: Matrix R -> Matrix R -> Spec
featureNormalizeSpec features expectedMatrix =
  describe "featureNormalize" $ do
    it "correctly normalizes the matrix values" $ do
      let normalizedMatrix = featureNormalize features
      normalizedMatrix `shouldSatisfy` (matrixEq expectedMatrix)

-- Helpers
readLinearRegressionSample :: FilePath -> IO (Matrix R, Matrix R, Vector R)
readLinearRegressionSample dataDir = do
  let linearRegressionFile = dataDir </> "linearRegression.csv"
  linearRegressionData <- decode NoHeader <$> LB.readFile linearRegressionFile
  let (features, vals) =
        splitMatrixOfSamples . V.toList . fromRight V.empty $
        linearRegressionData
  let normalizedDataFile = dataDir </> "lrFeatureNormalize.csv"
  normalizedLrData <- decode NoHeader <$> LB.readFile normalizedDataFile
  let normalizedFeatures =
        toMatrix . addOnesColumn . V.toList . fromRight V.empty $
        normalizedLrData
  return
    (toMatrix . addOnesColumn $ features, normalizedFeatures, toVector vals)

doubleEq :: Double -> Double -> Bool
doubleEq r1 r2 = abs (r1 - r2) <= 0.0001

matrixEq :: Matrix R -> Matrix R -> Bool
matrixEq mx1 mx2 =
  let valsMx1 = concat $ toListMatrix mx1
      valsMx2 = concat $ toListMatrix mx2
   in all (\(v1, v2) -> doubleEq v1 v2) $ zip valsMx1 valsMx2
