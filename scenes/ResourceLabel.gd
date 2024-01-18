extends Label

var resource_count = 0

func increment_resource_count():
	resource_count += 1
	self.set_text("Resources: " + str(resource_count))
	print("resource stored")
