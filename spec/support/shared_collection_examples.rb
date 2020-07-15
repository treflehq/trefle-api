# shared_examples "a collection response" do |measurement, measurement_methods|
#   measurement_methods.each do |measurement_method|
#     it "should return #{measurement} from ##{measurement_method}" do
#       subject.send(measurement_method).should == measurement
#     end
#   end
# end
